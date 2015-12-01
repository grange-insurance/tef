require 'spec_helper'
require 'database_cleaner'

describe 'Dispatcher, Integration' do

  let(:clazz) { TEF::Manager::Dispatcher }

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

    let(:mock_logger) { create_mock_logger }
    let(:mock_task_queue) { create_mock_task_queue }
    let(:mock_resource_manager) { create_mock_resource_manager }
    let(:mock_worker) { create_mock_worker }
    let(:mock_worker_collective) { create_mock_worker_collective(mock_worker) }

    let(:configuration) { {
        logger: mock_logger,
        resource_manager: mock_resource_manager,
        task_queue: mock_task_queue,
        worker_collective: mock_worker_collective,
    } }

    let(:dispatcher) { clazz.new(configuration) }


    after(:each) do
      DatabaseCleaner.clean
    end

    it_should_behave_like 'a logged component, integration level'


    describe 'control functionality' do

      before(:each) do
        @set_state_command = {type: 'set_state', data: 'paused'}
      end


      describe 'suite pausing' do

        before(:each) do
          # todo - create a helper method for generating tasks
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


        it 'pauses all tasks in the given suite' do
          suite_guid = 'dispatcher test suite'

          TEF::Manager::Task.where(suite_guid: suite_guid).each do |task|
            task.status = 'not paused'
            task.save
          end

          expect(TEF::Manager::Task.where(suite_guid: suite_guid).any? { |task| task.status == 'paused' }).to be false

          dispatcher.pause_suite(suite_guid)

          expect(TEF::Manager::Task.where(suite_guid: suite_guid).all? { |task| task.status == 'paused' }).to be true
        end

        it 'does not pause tasks that are not in the given suite' do
          suite_guid = 'dispatcher test suite'

          non_suite_task = TEF::Manager::Task.find_by(guid: 'test task 2')
          non_suite_task.suite_guid = 'a different suite'
          non_suite_task.save

          TEF::Manager::Task.all.each do |task|
            task.status = 'not paused'
            task.save
          end


          dispatcher.pause_suite(suite_guid)


          expect(TEF::Manager::Task.find_by(guid: 'test task 2').status).to_not eq('paused')
        end

        it "logs that it is pausing a suite's tasks" do
          suite_guid = 'dispatcher test suite'

          dispatcher.pause_suite(suite_guid)

          expect(mock_logger).to have_received(:info).with(/pausing.*#{suite_guid}/i)
        end

        it 'will log a warning if no tasks are found for the given suite' do
          suite_guid = 'foo'

          TEF::Manager::Task.all.each do |task|
            task.suite_guid = 'bar'
            task.save
          end


          dispatcher.pause_suite(suite_guid)


          expect(mock_logger).to have_received(:warn).with(/no tasks.*#{suite_guid}/i)
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

        it 'readies all tasks in the given suite' do
          suite_guid = 'dispatcher test suite'

          TEF::Manager::Task.where(suite_guid: suite_guid).each do |task|
            task.status = 'not ready'
            task.save
          end

          expect(TEF::Manager::Task.where(suite_guid: suite_guid).any? { |task| task.status == 'ready' }).to be false

          dispatcher.ready_suite(suite_guid)

          expect(TEF::Manager::Task.where(suite_guid: suite_guid).all? { |task| task.status == 'ready' }).to be true
        end

        it 'does not ready tasks that are not in the given suite' do
          suite_guid = 'dispatcher test suite'

          non_suite_task = TEF::Manager::Task.find_by(guid: 'test task 2')
          non_suite_task.suite_guid = 'a different suite'
          non_suite_task.save

          TEF::Manager::Task.all.each do |task|
            task.status = 'not ready'
            task.save
          end


          dispatcher.ready_suite(suite_guid)


          expect(TEF::Manager::Task.find_by(guid: 'test task 2').status).to_not eq('ready')
        end

        it "logs that it is readying a suite's tasks" do
          suite_guid = 'dispatcher test suite'

          dispatcher.ready_suite(suite_guid)

          expect(mock_logger).to have_received(:info).with(/readying.*#{suite_guid}/i)
        end

        it 'will log a warning if no tasks are found for the given suite' do
          suite_guid = 'foo'

          TEF::Manager::Task.all.each do |task|
            task.suite_guid = 'bar'
            task.save
          end


          dispatcher.ready_suite(suite_guid)


          expect(mock_logger).to have_received(:warn).with(/no tasks.*#{suite_guid}/i)
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

        it 'removes all tasks in the given suite' do
          suite_count = 3
          suite_guid = 'foobar'

          suite_count.times do
            task = TEF::Manager::Task.new
            task.suite_guid = suite_guid
            task.priority = 4
            task.guid = 'some guid'
            task.save
          end

          expect(TEF::Manager::Task.where(suite_guid: suite_guid).count).to eq(suite_count)

          dispatcher.stop_suite(suite_guid)

          expect(TEF::Manager::Task.where(suite_guid: suite_guid).count).to eq(0)
        end

        it 'does not remove tasks that are not in the given suite' do
          suite_count = 2
          suite_guid = 'foobar'

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


          dispatcher.stop_suite(suite_guid)


          expect(TEF::Manager::Task.find_by(guid: 'non target task')).to_not be_nil
        end

        it 'logs that it is stopping a task suite' do
          suite_guid = 'dispatcher test suite'

          dispatcher.stop_suite(suite_guid)

          expect(mock_logger).to have_received(:info).with(/stopping.*#{suite_guid}/i)
        end

        it 'will log a warning if no tasks are found for the given suite' do
          suite_guid = 'foo'

          TEF::Manager::Task.all.each do |task|
            task.suite_guid = 'bar'
            task.save
          end


          dispatcher.stop_suite(suite_guid)


          expect(mock_logger).to have_received(:warn).with(/no tasks.*#{suite_guid}/i)
        end

      end
    end
  end
end
