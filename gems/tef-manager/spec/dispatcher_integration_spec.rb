require 'spec_helper'
require 'database_cleaner'

describe 'Dispatcher, Integration' do

  clazz = TEF::Manager::Dispatcher

  describe 'instance level' do

    before(:all) do
      ActiveRecord::Base.time_zone_aware_attributes = true
      ActiveRecord::Base.default_timezone = :local

      db_config = YAML.load(File.open("#{tef_config}/database_#{tef_env}.yml"))
      ActiveRecord::Base.establish_connection(db_config)
      ActiveRecord::Base.table_name_prefix = "tef_#{tef_env}_"
      ActiveRecord::Base.logger = Logger.new(File.open('database.log', 'a'))

      #todo - fix the other database cleaning setups so that they work in non dev modes as well
      DatabaseCleaner.strategy = :truncation, {only: ["tef_#{tef_env}_tasks", "tef_#{tef_env}_task_resources"]}
      DatabaseCleaner.start
    end

    before(:each) do
      @mock_logger = create_mock_logger

      @mock_resource_manager = create_mock_resource_manager
      @mock_task_queue = create_mock_task_queue(create_mock_task, nil)

      @mock_worker = create_mock_worker
      @mock_worker_collective = create_mock_worker_collective(@mock_worker)

      @mock_exchange = create_mock_exchange
      @mock_channel = create_mock_channel(@mock_exchange)
      @mock_control_queue = create_mock_queue

      @options = {
          logger: @mock_logger,
          control_queue: @mock_control_queue,
          resource_manager: @mock_resource_manager,
          task_queue: @mock_task_queue,
          worker_collective: @mock_worker_collective,
          dispatch_interval: 1
      }

      @dispatcher = clazz.new(@options)
    end

    after(:each) do
      DatabaseCleaner.clean
    end

    it_should_behave_like 'a logged component, integration level' do
      let(:clazz) { clazz }
      let(:configuration) { @options }
    end


    it 'subscribes to the control queue when it is started' do
      begin
        @dispatcher.start

        expect(@mock_control_queue).to have_received(:subscribe_with)
      ensure
        @dispatcher.stop
      end
    end

    it 'changes its state to running when it is started' do
      begin
        @dispatcher.start

        expect(@dispatcher.state).to eq(:running)
      ensure
        @dispatcher.stop
      end
    end

    it 'changes its state to stopped when it is stopped' do
      @dispatcher.stop

      expect(@dispatcher.state).to eq(:stopped)
    end


    describe 'task dispatch loop' do

      before(:each) do
        @test_interval = 1
        @options[:dispatch_interval] = @test_interval

        @dispatcher = clazz.new(@options)
      end


      it 'starting the dispatcher starts the dispatch loop' do
        expect(@mock_worker).to_not have_received(:work)

        begin
          @dispatcher.start

          # Multi-threadedness is not an exact science. This should be enough of a buffer that even particularly
          # sleepy threads have time to do their thing.
          sleep(@test_interval + 0.1)

          expect(@mock_worker).to have_received(:work).once

          # Loading up another task for the next dispatch cycle
          allow(@mock_task_queue).to receive(:pop).and_return(create_mock_task, nil)
          sleep(@test_interval + 0.1)

          expect(@mock_worker).to have_received(:work).twice
        ensure
          # Don't want the dispatch thread to keep going once the test is over
          @dispatcher.stop
        end
      end

      it 'stopping the dispatcher stops the dispatch loop' do
        expect(@mock_worker).to_not have_received(:work)

        begin
          @dispatcher.start

          # Multi-threadedness is not an exact science. This should be enough of a buffer that even particularly
          # sleepy threads have time to do their thing.
          sleep(@test_interval + 0.1)

          expect(@mock_worker).to have_received(:work).once

          @dispatcher.stop

          # Loading up another task for the next dispatch cycle
          allow(@mock_task_queue).to receive(:pop).and_return(create_mock_task, nil)

          # And another interval to give it a chance to not stop
          sleep(@test_interval + 0.1)

          # The dispatch wouldn't do anything at this point anyway due to not being in a running
          # state but the point is to not even be in the loop anymore
          expect(@mock_logger).to_not have_received(:info).with(/Not dispatching/i)
          expect(@mock_worker).to have_received(:work).once
        ensure
          # Don't want the dispatch thread to keep going once the test is over
          @dispatcher.stop
        end
      end

      it 'stops the dispatch loop on its own if the dispatcher can no longer be stopped (e.g. manager node/process crashes)' do
        skip('This may happen anyway. Will need to actually make sure that it is a problem first by playing with a live manager.')
      end

    end


    describe 'control functionality' do

      before(:each) do
        @set_state_command = {type: 'set_state', data: 'paused'}
        @pause_suite_command = {type: 'pause_suite', data: 'dispatcher test suite'}
        @stop_suite_command = {type: 'stop_suite', data: 'dispatcher test suite'}
        @ready_suite_command = {type: 'ready_suite', data: 'dispatcher test suite'}
      end

      it_should_behave_like 'a message controlled component', clazz, :control_queue do
        let(:needs_started) { true }
        let(:configuration) { @options }

        let(:test_task) { {type: 'set_state',
                           data: 'paused'
        } }

      end

      describe 'setting dispatcher state' do

        it 'can be sent a control message for its state update control point' do
          control_queue = create_fake_publisher(@mock_channel)
          @options[:control_queue] = control_queue
          @set_state_command[:data] = 'stopped'

          dispatcher = clazz.new(@options)

          begin
            dispatcher.start
            dispatcher.state = :paused

            control_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@set_state_command))

            expect(dispatcher.state).to eq(:stopped)
          ensure
            dispatcher.stop
          end
        end
      end

      describe 'suite pausing' do

        before(:each) do
          task = TEF::Manager::Task.new
          task.suite_guid = 'dispatcher test suite'
          task.priority = 4
          task.guid = 'test task 1'
          task.save

          task = TEF::Manager::Task.new
          task.suite_guid = 'dispatcher test suite'
          task.priority = 4
          task.guid = 'test task 2'
          task.save

          task = TEF::Manager::Task.new
          task.suite_guid = 'dispatcher test suite'
          task.priority = 4
          task.guid = 'test task 3'
          task.save
        end

        it 'can be sent a control message for its suite pausing control point' do
          suite_guid = 'dispatcher test suite'
          control_queue = create_fake_publisher(@mock_channel)
          @options[:control_queue] = control_queue
          @pause_suite_command[:data] = suite_guid

          TEF::Manager::Task.where(suite_guid: suite_guid).each do |task|
            task.status = 'not paused'
            task.save
          end


          expect(TEF::Manager::Task.where(suite_guid: suite_guid).any? { |task| task.status == 'paused' }).to be false

          dispatcher = clazz.new(@options)

          begin
            dispatcher.start

            control_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@pause_suite_command))

            expect(TEF::Manager::Task.where(suite_guid: suite_guid).all? { |task| task.status == 'paused' }).to be true
          ensure
            dispatcher.stop
          end
        end

        it 'pauses all tasks in the given suite' do
          suite_guid = 'dispatcher test suite'
          @pause_suite_command[:data] = suite_guid

          TEF::Manager::Task.where(suite_guid: suite_guid).each do |task|
            task.status = 'not paused'
            task.save
          end

          expect(TEF::Manager::Task.where(suite_guid: suite_guid).any? { |task| task.status == 'paused' }).to be false

          @dispatcher.control_pause_suite(@pause_suite_command)

          expect(TEF::Manager::Task.where(suite_guid: suite_guid).all? { |task| task.status == 'paused' }).to be true
        end

        it 'does not pause tasks that are not in the given suite' do
          suite_guid = 'dispatcher test suite'
          @pause_suite_command[:data] = suite_guid

          non_suite_task = TEF::Manager::Task.find_by(guid: 'test task 2')
          non_suite_task.suite_guid = 'a different suite'
          non_suite_task.save

          TEF::Manager::Task.all.each do |task|
            task.status = 'not paused'
            task.save
          end


          @dispatcher.control_pause_suite(@pause_suite_command)


          expect(TEF::Manager::Task.find_by(guid: 'test task 2').status).to_not eq('paused')
        end

        it "logs that it is pausing a suite's tasks" do
          suite_guid = 'dispatcher test suite'
          @pause_suite_command[:data] = suite_guid


          @dispatcher.control_pause_suite(@pause_suite_command)


          expect(@mock_logger).to have_received(:info).with(/pausing.*#{suite_guid}/i)
        end

        it 'will log a warning if no tasks are found for the given suite' do
          suite_guid = 'foo'
          @pause_suite_command[:data] = suite_guid

          TEF::Manager::Task.all.each do |task|
            task.suite_guid = 'bar'
            task.save
          end


          @dispatcher.control_pause_suite(@pause_suite_command)


          expect(@mock_logger).to have_received(:warn).with(/no tasks.*#{suite_guid}/i)
        end

      end

      describe 'suite readying' do

        before(:each) do
          task = TEF::Manager::Task.new
          task.suite_guid = 'dispatcher test suite'
          task.priority = 4
          task.guid = 'test task 1'
          task.save

          task = TEF::Manager::Task.new
          task.suite_guid = 'dispatcher test suite'
          task.priority = 4
          task.guid = 'test task 2'
          task.save

          task = TEF::Manager::Task.new
          task.suite_guid = 'dispatcher test suite'
          task.priority = 4
          task.guid = 'test task 3'
          task.save
        end

        it 'can be sent a control message for its suite readying control point' do
          suite_guid = 'dispatcher test suite'
          control_queue = create_fake_publisher(@mock_channel)
          @options[:control_queue] = control_queue
          @ready_suite_command[:data] = suite_guid

          TEF::Manager::Task.where(suite_guid: suite_guid).each do |task|
            task.status = 'not ready'
            task.save
          end


          expect(TEF::Manager::Task.where(suite_guid: suite_guid).any? { |task| task.status == 'ready' }).to be false

          dispatcher = clazz.new(@options)

          begin
            dispatcher.start

            control_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@ready_suite_command))

            expect(TEF::Manager::Task.where(suite_guid: suite_guid).all? { |task| task.status == 'ready' }).to be true
          ensure
            dispatcher.stop
          end
        end

        it 'readies all tasks in the given suite' do
          suite_guid = 'dispatcher test suite'
          @ready_suite_command[:data] = suite_guid

          TEF::Manager::Task.where(suite_guid: suite_guid).each do |task|
            task.status = 'not ready'
            task.save
          end

          expect(TEF::Manager::Task.where(suite_guid: suite_guid).any? { |task| task.status == 'ready' }).to be false

          @dispatcher.control_ready_suite(@ready_suite_command)

          expect(TEF::Manager::Task.where(suite_guid: suite_guid).all? { |task| task.status == 'ready' }).to be true
        end

        it 'does not ready tasks that are not in the given suite' do
          suite_guid = 'dispatcher test suite'
          @ready_suite_command[:data] = suite_guid

          non_suite_task = TEF::Manager::Task.find_by(guid: 'test task 2')
          non_suite_task.suite_guid = 'a different suite'
          non_suite_task.save

          TEF::Manager::Task.all.each do |task|
            task.status = 'not ready'
            task.save
          end


          @dispatcher.control_ready_suite(@ready_suite_command)


          expect(TEF::Manager::Task.find_by(guid: 'test task 2').status).to_not eq('ready')
        end

        it "logs that it is readying a suite's tasks" do
          suite_guid = 'dispatcher test suite'
          @ready_suite_command[:data] = suite_guid


          @dispatcher.control_ready_suite(@ready_suite_command)


          expect(@mock_logger).to have_received(:info).with(/readying.*#{suite_guid}/i)
        end

        it 'will log a warning if no tasks are found for the given suite' do
          suite_guid = 'foo'
          @ready_suite_command[:data] = suite_guid

          TEF::Manager::Task.all.each do |task|
            task.suite_guid = 'bar'
            task.save
          end


          @dispatcher.control_ready_suite(@ready_suite_command)


          expect(@mock_logger).to have_received(:warn).with(/no tasks.*#{suite_guid}/i)
        end

      end

      describe 'suite stopping' do

        before(:each) do
          task = TEF::Manager::Task.new
          task.suite_guid = 'dispatcher test suite'
          task.priority = 4
          task.guid = 'test task 1'
          task.save

          task = TEF::Manager::Task.new
          task.suite_guid = 'dispatcher test suite'
          task.priority = 4
          task.guid = 'test task 2'
          task.save

          task = TEF::Manager::Task.new
          task.suite_guid = 'dispatcher test suite'
          task.priority = 4
          task.guid = 'test task 3'
          task.save
        end

        it 'can be sent a control message for its suite stopping control point' do
          suite_count = 3
          suite_guid = 'foobar'
          @stop_suite_command[:data] = suite_guid
          control_queue = create_fake_publisher(@mock_channel)
          @options[:control_queue] = control_queue

          suite_count.times do
            task = TEF::Manager::Task.new
            task.suite_guid = suite_guid
            task.priority = 4
            task.guid = 'some guid'
            task.save
          end


          expect(TEF::Manager::Task.where(suite_guid: suite_guid).count).to eq(suite_count)

          dispatcher = clazz.new(@options)

          begin
            dispatcher.start

            control_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@stop_suite_command))

            expect(TEF::Manager::Task.where(suite_guid: suite_guid).count).to eq(0)
          ensure
            dispatcher.stop
          end
        end

        it 'removes all tasks in the given suite' do
          suite_count = 3
          suite_guid = 'foobar'
          @stop_suite_command[:data] = suite_guid

          suite_count.times do
            task = TEF::Manager::Task.new
            task.suite_guid = suite_guid
            task.priority = 4
            task.guid = 'some guid'
            task.save
          end

          expect(TEF::Manager::Task.where(suite_guid: suite_guid).count).to eq(suite_count)

          @dispatcher.control_stop_suite(@stop_suite_command)

          expect(TEF::Manager::Task.where(suite_guid: suite_guid).count).to eq(0)
        end

        it 'does not remove tasks that are not in the given suite' do
          suite_count = 2
          suite_guid = 'foobar'
          @stop_suite_command[:data] = suite_guid

          suite_count.times do
            task = TEF::Manager::Task.new
            task.suite_guid = suite_guid
            task.priority = 4
            task.guid = 'some guid'
            task.save
          end

          task = TEF::Manager::Task.new
          task.suite_guid = 'a different suite'
          task.priority = 4
          task.guid = 'non target task'
          task.save


          @dispatcher.control_stop_suite(@stop_suite_command)


          expect(TEF::Manager::Task.find_by(guid: 'non target task')).to_not be_nil
        end

        it 'logs that it is stopping a task suite' do
          suite_guid = 'dispatcher test suite'
          @stop_suite_command[:data] = suite_guid


          @dispatcher.control_stop_suite(@stop_suite_command)


          expect(@mock_logger).to have_received(:info).with(/stopping.*#{suite_guid}/i)
        end

        it 'will log a warning if no tasks are found for the given suite' do
          suite_guid = 'foo'
          @stop_suite_command[:data] = suite_guid

          TEF::Manager::Task.all.each do |task|
            task.suite_guid = 'bar'
            task.save
          end


          @dispatcher.control_stop_suite(@stop_suite_command)


          expect(@mock_logger).to have_received(:warn).with(/no tasks.*#{suite_guid}/i)
        end

      end
    end
  end
end
