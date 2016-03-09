require 'spec_helper'
require 'rspec/mocks'
require 'database_cleaner'


describe 'Manager, Integration' do

  let(:clazz) { TEF::Manager::Manager }

  let(:mock_dispatcher) { double('mock_dispatcher').as_null_object }
  let(:mock_task_queue) { create_mock_task_queue }
  let(:mock_worker_collective) { double('mock_worker_collective').as_null_object }
  let(:mock_input_queue) { create_mock_queue }
  let(:mock_logger) { create_mock_logger }
  let(:configuration) { {in_queue: mock_input_queue,
                         dispatcher: mock_dispatcher,
                         task_queue: mock_task_queue,
                         worker_collective: mock_worker_collective,
                         logger: mock_logger
  } }
  let(:manager) { clazz.new(configuration) }


  describe 'common behavior' do
    it_should_behave_like 'a logged component, integration level'
    # todo - make other things responsive as well?
    it_should_behave_like 'a responsive component, integration level', [:in_queue], {needs_started: true}
  end


  describe 'unique behavior' do

    it 'should be listening to its inbound queue once it has been started' do
      begin
        manager.start

        expect(mock_input_queue).to have_received(:subscribe_with)
      ensure
        manager.stop
      end
    end

    it 'changes its state to running when it is started' do
      begin
        manager.start

        expect(manager.state).to eq(:running)
      ensure
        manager.stop
      end
    end

    it 'changes its state to stopped when it is stopped' do
      manager.stop

      expect(manager.state).to eq(:stopped)
    end


    describe 'setting manager state' do

      let(:set_state_command) { {type: 'set_state', data: 'paused'} }

      it 'sets the state of the manager in response to a state update message' do
        control_queue = create_fake_publisher(create_mock_channel)
        configuration[:in_queue] = control_queue
        set_state_command[:data] = 'stopped'

        manager = clazz.new(configuration)

        begin
          manager.start
          manager.set_state(:paused)

          control_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(set_state_command))

          expect(manager.state).to eq(:stopped)
        ensure
          manager.stop
        end
      end

      it 'can gracefully handle not being provided with state data with which to set the state' do
        control_queue = create_fake_publisher(create_mock_channel)
        configuration[:in_queue] = control_queue
        set_state_command.delete(:data)

        manager = clazz.new(configuration)

        begin
          manager.start

          expect { control_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(set_state_command)) }.to_not raise_error

        ensure
          manager.stop
        end
      end

      it 'logs when it is not provided with state data with which to set the state' do
        control_queue = create_fake_publisher(create_mock_channel)
        configuration[:in_queue] = control_queue
        set_state_command.delete(:data)
        json_message = JSON.generate(set_state_command)
        manager = clazz.new(configuration)

        begin
          manager.start

          control_queue.call(create_mock_delivery_info, create_mock_properties, json_message)

          expect(mock_logger).to have_received(:error).with(/INVALID_JSON\|NO_DATA\|#{json_message}/i)
        ensure
          manager.stop
        end
      end

      it 'can gracefully handle being given an invalid state' do
        control_queue = create_fake_publisher(create_mock_channel)
        configuration[:in_queue] = control_queue
        set_state_command[:data] = 'not an approved state'

        manager = clazz.new(configuration)

        begin
          manager.start

          expect { control_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(set_state_command)) }.to_not raise_error

        ensure
          manager.stop
        end
      end

      it 'logs when it is given an invalid state' do
        control_queue = create_fake_publisher(create_mock_channel)
        configuration[:in_queue] = control_queue
        set_state_command[:data] = 'not an approved state'
        json_message = JSON.generate(set_state_command)

        manager = clazz.new(configuration)

        begin
          manager.start

          control_queue.call(create_mock_delivery_info, create_mock_properties, json_message)

          expect(mock_logger).to have_received(:error).with(/INVALID_JSON\|INVALID_STATE\|#{set_state_command[:data]}\|#{json_message}/i)
        ensure
          manager.stop
        end
      end

      it 'updates the state of the manager on a good state update' do
        control_queue = create_fake_publisher(create_mock_channel)
        configuration[:in_queue] = control_queue
        set_state_command[:data] = :paused

        manager = clazz.new(configuration)

        begin
          manager.start

          control_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(set_state_command))

          expect(manager.state).to eq(:paused)
        ensure
          manager.stop
        end
      end

    end


    describe 'worker management' do

      let(:mock_exchange) { create_mock_exchange }
      let(:mock_channel) { create_mock_channel(mock_exchange) }
      let(:get_workers_message) { {type: "get_workers"} }
      let(:worker_status_message) { {type: "worker_status",
                                     worker_type: "type 1",
                                     name: "worker_foo",
                                     status: 'some_status',
                                     exchange_name: "tef.dev.worker_foo"} }


      it 'returns a data dump of all workers in response to a get workers message' do
        worker_data = [{some_test: 'data'}]
        json_data = JSON.generate(worker_data)
        allow(mock_worker_collective).to receive(:get_workers).and_return(worker_data)

        properties = create_mock_properties
        message_queue = create_fake_publisher(mock_channel)
        configuration[:in_queue] = message_queue
        manager = clazz.new(configuration)

        begin
          manager.start

          message_queue.call(create_mock_delivery_info, properties, JSON.generate(get_workers_message))

          expect(mock_worker_collective).to have_received(:get_workers)

          expect(mock_exchange).to have_received(:publish).with("{\"response\":#{json_data}}", routing_key: properties.reply_to, correlation_id: properties.correlation_id)
        ensure
          manager.stop
        end
      end

      it 'sets the status of a worker in response to a get worker status message' do
        message_queue = create_fake_publisher(mock_channel)
        configuration[:in_queue] = message_queue
        manager = clazz.new(configuration)

        begin
          manager.start

          message_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(worker_status_message))

          expect(mock_worker_collective).to have_received(:set_worker_status).with(worker_status_message)
        ensure
          manager.stop
        end
      end

      # todo - add a timestamp to the heartbeat and not add workers from old heartbeats (such as might exist if the manager dies and worker heartbeats build up in Rabbit in the mean time and then those workers die before the manager returns and finds a bunch of heartbeats for now dead workers)
      it 'adds the worker to its known workers if it receives a status update from an unknown worker' do
        worker_collective = TEF::Manager::WorkerCollective.new({resource_manager: double('mock_dispatcher').as_null_object}) # Need a real one for this test
        configuration[:worker_collective] = worker_collective
        message_queue = create_fake_publisher(mock_channel)
        configuration[:in_queue] = message_queue
        manager = clazz.new(configuration)

        begin
          manager.start


          expect(worker_collective.workers['some_new_worker']).to be_nil

          worker_status_message[:name] = 'some_new_worker'
          message_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(worker_status_message))

          expect(worker_collective.workers['some_new_worker']).to_not be_nil
        ensure
          manager.stop
        end
      end

      bad_statuses = [:exchange_name, :status]

      bad_statuses.each do |status|

        it "will not automatically add the new worker on a bad status update (missing #{status} in data)" do
          worker_collective = TEF::Manager::WorkerCollective.new({resource_manager: double('mock_dispatcher').as_null_object}) # Need a real one for this test
          configuration[:worker_collective] = worker_collective
          message_queue = create_fake_publisher(mock_channel)
          configuration[:in_queue] = message_queue
          manager = clazz.new(configuration)

          begin
            manager.start

            expect(worker_collective.workers['some_new_worker']).to be_nil

            worker_status_message[:name] = 'some_new_worker'
            worker_status_message.delete(status)
            message_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(worker_status_message))

            expect(worker_collective.workers['some_new_worker']).to be_nil
          ensure
            manager.stop
          end
        end

      end

    end


    describe 'task management' do

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

      after(:each) do
        DatabaseCleaner.clean
      end


      let(:mock_exchange) { create_mock_exchange }
      let(:mock_channel) { create_mock_channel(mock_exchange) }


      describe 'task storing' do

        let(:task_message) { {type: "task", task_type: "type_foo", guid: "task_foo", priority: 5, resources: "foo|bar|baz", task_data: "ew0KICAibWVzc2FnZSI6ICJIZWxsbyBXb3JsZCINCn0="} }


        it 'stores the received task in response to a task message' do
          suite_guid = 'manager test suite'
          message_queue = create_fake_publisher(mock_channel)
          configuration[:in_queue] = message_queue
          task_message[:data] = suite_guid


          manager = clazz.new(configuration)

          begin
            manager.start

            message_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(task_message))

            expect(mock_task_queue).to have_received(:push).with(task_message)
          ensure
            manager.stop
          end
        end

      end


      describe 'suite pausing' do

        let(:pause_suite_message) { {type: 'pause_suite', data: 'test suite foo'} }


        it 'pauses a suite in response to a pause suite message' do
          suite_guid = 'manager test suite'
          message_queue = create_fake_publisher(mock_channel)
          configuration[:in_queue] = message_queue
          pause_suite_message[:data] = suite_guid


          manager = clazz.new(configuration)

          begin
            manager.start

            message_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(pause_suite_message))

            expect(mock_dispatcher).to have_received(:pause_suite).with(suite_guid)
          ensure
            manager.stop
          end
        end

        it 'gracefully handles not being provided with guid data with which to pause a suite' do
          message_queue = create_fake_publisher(mock_channel)
          configuration[:in_queue] = message_queue
          pause_suite_message.delete(:data)


          manager = clazz.new(configuration)

          begin
            manager.start

            expect { message_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(pause_suite_message)) }.to_not raise_error
          ensure
            manager.stop
          end
        end

        it 'logs when it is not provided with guid data with which to pause a suite' do
          message_queue = create_fake_publisher(mock_channel)
          configuration[:in_queue] = message_queue
          pause_suite_message.delete(:data)
          json_message = JSON.generate(pause_suite_message)

          manager = clazz.new(configuration)

          begin
            manager.start

            message_queue.call(create_mock_delivery_info, create_mock_properties, json_message)

            expect(mock_logger).to have_received(:error).with(/INVALID_JSON\|NO_DATA\|#{json_message}/i)
          ensure
            manager.stop
          end
        end

      end

      describe 'suite readying' do

        let(:ready_suite_message) { {type: 'ready_suite', data: 'test suite foo'} }


        it 'readies a suite in response to a ready suite message' do
          suite_guid = 'manager test suite'
          message_queue = create_fake_publisher(mock_channel)
          configuration[:in_queue] = message_queue
          ready_suite_message[:data] = suite_guid


          manager = clazz.new(configuration)

          begin
            manager.start
            8
            message_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(ready_suite_message))

            expect(mock_dispatcher).to have_received(:ready_suite).with(suite_guid)
          ensure
            manager.stop
          end
        end

        it 'gracefully handles not being provided with guid data with which to ready a suite' do
          message_queue = create_fake_publisher(mock_channel)
          configuration[:in_queue] = message_queue
          ready_suite_message.delete(:data)


          manager = clazz.new(configuration)

          begin
            manager.start

            expect { message_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(ready_suite_message)) }.to_not raise_error
          ensure
            manager.stop
          end
        end

        it 'logs when it is not provided with guid data with which to ready a suite' do
          message_queue = create_fake_publisher(mock_channel)
          configuration[:in_queue] = message_queue
          ready_suite_message.delete(:data)
          json_message = JSON.generate(ready_suite_message)

          manager = clazz.new(configuration)

          begin
            manager.start

            message_queue.call(create_mock_delivery_info, create_mock_properties, json_message)

            expect(mock_logger).to have_received(:error).with(/INVALID_JSON\|NO_DATA\|#{json_message}/i)
          ensure
            manager.stop
          end
        end

      end

      describe 'suite stopping' do

        let(:stop_suite_message) { {type: 'stop_suite', data: 'test suite foo'} }


        it 'stops a suite in response to a stop suite message' do
          suite_guid = 'manager test suite'
          message_queue = create_fake_publisher(mock_channel)
          configuration[:in_queue] = message_queue
          stop_suite_message[:data] = suite_guid


          manager = clazz.new(configuration)

          begin
            manager.start

            message_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(stop_suite_message))

            expect(mock_dispatcher).to have_received(:stop_suite).with(suite_guid)
          ensure
            manager.stop
          end
        end

        it 'gracefully handles not being provided with guid data with which to stop a suite' do
          message_queue = create_fake_publisher(mock_channel)
          configuration[:in_queue] = message_queue
          stop_suite_message.delete(:data)


          manager = clazz.new(configuration)

          begin
            manager.start

            expect { message_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(stop_suite_message)) }.to_not raise_error
          ensure
            manager.stop
          end
        end

        it 'logs when it is not provided with guid data with which to stop a suite' do
          message_queue = create_fake_publisher(mock_channel)
          configuration[:in_queue] = message_queue
          stop_suite_message.delete(:data)
          json_message = JSON.generate(stop_suite_message)

          manager = clazz.new(configuration)

          begin
            manager.start

            message_queue.call(create_mock_delivery_info, create_mock_properties, json_message)

            expect(mock_logger).to have_received(:error).with(/INVALID_JSON\|NO_DATA\|#{json_message}/i)
          ensure
            manager.stop
          end
        end

      end

    end


    describe 'dispatching tasks' do


      let(:dispatch_tasks_command) { {type: 'dispatch_tasks'} }


      it 'does not dispatch tasks unless it is running' do
        input_queue = create_fake_publisher(create_mock_channel)
        configuration[:in_queue] = input_queue
        manager = clazz.new(configuration)

        begin
          manager.start

          no_dispatch_states = [:paused, :stopped]
          no_dispatch_states.each do |state|
            manager.set_state(state)

            input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(dispatch_tasks_command))

            expect(mock_dispatcher).not_to have_received(:dispatch_tasks)
          end

          manager.set_state(:running)
          input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(dispatch_tasks_command))

          expect(mock_dispatcher).to have_received(:dispatch_tasks)
        ensure
          manager.stop
        end

      end

      it 'logs if it is not dispatching due to its state' do
        input_queue = create_fake_publisher(create_mock_channel)
        configuration[:in_queue] = input_queue
        manager = clazz.new(configuration)

        begin
          manager.start

          manager.set_state(:non_runnning_state)
          input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(dispatch_tasks_command))

          expect(mock_logger).to have_received(:info).with(/not.*dispatching.*non_runnning_state/i)
        ensure
          manager.stop
        end
      end

      describe 'task dispatch loop' do

        let(:mock_worker) { create_mock_worker }
        let(:mock_worker_collective) { create_mock_worker_collective(mock_worker) }
        let(:mock_task_queue) { create_mock_task_queue([create_mock_task]) }
        let(:mock_message_queue) { create_mock_queue }
        let(:task_dispatch_message) { JSON.generate({type: 'dispatch_tasks'}) }


        before(:all) do
          @connection = Bunny.new(username: 'guest', password: 'guest')

          @connection.start
        end

        before(:each) do
          configuration[:in_queue] = mock_message_queue

          @test_interval = 1
          configuration[:dispatch_interval] = @test_interval
          configuration[:dispatcher] = TEF::Manager::Dispatcher.new({worker_collective: mock_worker_collective,
                                                                     resource_manager: create_mock_resource_manager,
                                                                     task_queue: mock_task_queue})

          @manager = clazz.new(configuration)
        end


        it 'starting the manager starts the dispatch loop' do
          expect(mock_message_queue).to_not have_received(:publish)

          begin
            @manager.start

            # Multi-threadedness is not an exact science. This should be enough of a buffer that even particularly
            # sleepy threads have time to do their thing.
            sleep(@test_interval + 0.1)

            expect(mock_message_queue).to have_received(:publish).once.with(task_dispatch_message)

            sleep(@test_interval + 0.1)

            expect(mock_message_queue).to have_received(:publish).twice.with(task_dispatch_message)
          ensure
            # Don't want the dispatch thread to keep going once the test is over
            @manager.stop
          end
        end

        it 'stopping the manager stops the dispatch loop' do
          expect(mock_message_queue).to_not have_received(:publish)

          begin
            @manager.start

            # Multi-threadedness is not an exact science. This should be enough of a buffer that even particularly
            # sleepy threads have time to do their thing.
            sleep(@test_interval + 0.1)

            expect(mock_message_queue).to have_received(:publish).once.with(task_dispatch_message)

            @manager.stop

            # And another interval to give it a chance to not stop
            sleep(@test_interval + 0.1)

            expect(mock_message_queue).to have_received(:publish).once
          ensure
            # Don't want the dispatch thread to keep going once the test is over
            @manager.stop
          end
        end

        it 'stops the dispatch loop on its own if the manager can no longer be stopped (e.g. manager node/process crashes)' do
          skip('This may happen anyway. Will need to actually make sure that it is a problem first by playing with a live manager node.')
        end

      end

    end

  end

end
