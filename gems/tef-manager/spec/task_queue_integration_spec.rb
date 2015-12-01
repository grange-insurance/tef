require 'spec_helper'
require 'active_record'
require 'database_cleaner'


def generic_stored_task_data
  {guid: 'some_task', status: 'ready'}
end


describe 'TaskQueue, Integration' do

  let(:clazz) { TEF::Manager::TaskQueue }

  let(:task_message) { {type: "task", task_type: "type_1", guid: "test_guid", priority: 5, resources: "pipe|delminated|list", task_data: "ew0KICAibWVzc2FnZSI6ICJIZWxsbyBXb3JsZCINCn0="} }
  let(:mock_logger) { create_mock_logger }
  let(:configuration) { {logger: mock_logger} }
  let(:task_queue) { clazz.new(configuration) }


  describe 'common behavior' do
    it_should_behave_like 'a logged component, integration level'
  end


  describe 'specific behavior' do

    before(:all) do
      ActiveRecord::Base.time_zone_aware_attributes = true
      ActiveRecord::Base.default_timezone = :local

      db_config = YAML.load(File.open("#{tef_config}/database_#{tef_env}.yml"))
      ActiveRecord::Base.establish_connection(db_config)
      ActiveRecord::Base.table_name_prefix = "tef_#{tef_env}_"
      ActiveRecord::Base.logger = Logger.new(File.open('database.log', 'a'))

      DatabaseCleaner.strategy = :truncation, {only: %w(tef_dev_tasks tef_dev_task_resources)}
      DatabaseCleaner.start
    end

    before(:each) do
      DatabaseCleaner.clean
    end


    describe 'task storing' do

      it 'storing a task into the queue returns true if successful' do
        expect(task_queue.push(task_message)).to be true
      end

      it 'stores the task when it is pushed' do
        task_message[:guid] = 'foo'
        expect(TEF::Manager::Task.where(guid: 'foo').count).to eq(0)

        task_queue.push(task_message)

        expect(TEF::Manager::Task.where(guid: 'foo').count).to eq(1)
      end

      it 'tasks are set to a ready state when stored' do
        task_queue.push(task_message)

        expect(TEF::Manager::Task.find_by(guid: 'test_guid').status).to eq('ready')
      end

      it 'records the resources used by a received task' do
        task_message[:resources] = 'res1|res2|res3'

        task_queue.push(task_message)

        expect(TEF::Manager::TaskResource.count).to eq(3)
        expect(TEF::Manager::TaskResource.where(resource_name: 'res1').count).to eq(1)
        expect(TEF::Manager::TaskResource.where(resource_name: 'res2').count).to eq(1)
        expect(TEF::Manager::TaskResource.where(resource_name: 'res3').count).to eq(1)
      end

      it 'logs when it queues a task that has no type' do
        task_message.delete(:task_type)

        task_queue.push(task_message)

        expect(mock_logger).to have_received(:warn).with(/task test_guid.*no task type.*#{Regexp.escape(task_message.to_s)}/i)

        # Still stores it
        expect(TEF::Manager::Task.count).to eq(1)
      end
    end

    describe 'task retrieving' do

      it 'pulls the highest priority task from the queue' do
        TEF::Manager::Task.create(generic_stored_task_data.merge(guid: 'middle_task', priority: 5))
        TEF::Manager::Task.create(generic_stored_task_data.merge(guid: 'highest_task', priority: 6))
        TEF::Manager::Task.create(generic_stored_task_data.merge(guid: 'lowest_task', priority: 2))

        expect(TEF::Manager::Task.count).to eq(3)

        task = task_queue.pop([], [])
        expect(task.guid).to eq('highest_task')
      end

      it 'only pulls tasks for which there are workers' do
        TEF::Manager::Task.create(generic_stored_task_data.merge(task_type: 'type_1', guid: 'middle_task', priority: 5))
        TEF::Manager::Task.create(generic_stored_task_data.merge(task_type: 'type_2', guid: 'highest_task', priority: 6))
        TEF::Manager::Task.create(generic_stored_task_data.merge(task_type: 'type_3', guid: 'lowest_task', priority: 2))

        expect(TEF::Manager::Task.count).to eq(3)


        task = task_queue.pop(nil, ['type_3', 'type_4'])


        expect(task.guid).to eq('lowest_task')
      end

      # todo - Change this so that no worker types really means no worker types. 'All types' has no
      # meaning within the context of the framework
      it 'specifying no worker types (i.e. an empty array) will return all worker types' do
        TEF::Manager::Task.create(generic_stored_task_data.merge(task_type: 'type_1', guid: 'middle_task', priority: 5))
        TEF::Manager::Task.create(generic_stored_task_data.merge(task_type: 'type_2', guid: 'highest_task', priority: 6))
        TEF::Manager::Task.create(generic_stored_task_data.merge(task_type: 'type_3', guid: 'lowest_task', priority: 2))

        expect(TEF::Manager::Task.count).to eq(3)


        task = task_queue.pop(nil, [])


        expect(task.guid).to eq('highest_task')
      end


      it 'only pulls tasks for which resources are available' do
        TEF::Manager::Task.create(generic_stored_task_data.merge(task_type: 'type_1', guid: 'middle_task', priority: 5))
        TEF::Manager::TaskResource.create(task_id: 1, resource_name: 'res_1')
        TEF::Manager::TaskResource.create(task_id: 1, resource_name: 'res_2')
        TEF::Manager::Task.create(generic_stored_task_data.merge(task_type: 'type_2', guid: 'highest_task', priority: 6))
        TEF::Manager::TaskResource.create(task_id: 2, resource_name: 'res_1')
        TEF::Manager::TaskResource.create(task_id: 2, resource_name: 'res_3')
        TEF::Manager::Task.create(generic_stored_task_data.merge(task_type: 'type_3', guid: 'lowest_task', priority: 2))
        TEF::Manager::TaskResource.create(task_id: 3, resource_name: 'res_2')
        TEF::Manager::TaskResource.create(task_id: 3, resource_name: 'res_3')

        expect(TEF::Manager::Task.count).to eq(3)


        task = task_queue.pop(['res_3'], nil)


        expect(task.guid).to eq('middle_task')
      end

      it 'will not retrieve a task that has been dispatched' do
        TEF::Manager::Task.create(generic_stored_task_data.merge(task_type: 'type_1', guid: 'middle_task', priority: 5))
        TEF::Manager::Task.create(generic_stored_task_data.merge(task_type: 'type_2', guid: 'highest_task', priority: 6, dispatched: DateTime.now))
        TEF::Manager::Task.create(generic_stored_task_data.merge(task_type: 'type_3', guid: 'lowest_task', priority: 2))

        expect(TEF::Manager::Task.count).to eq(3)


        task = task_queue.pop([], [])


        expect(task.guid).to eq('middle_task')
      end

      #todo - DRY out all of the duplication in this section of testing

      it 'will not retrieve a task that has been paused' do
        TEF::Manager::Task.create(generic_stored_task_data.merge(task_type: 'type_1', guid: 'middle_task', priority: 5))
        TEF::Manager::Task.create(generic_stored_task_data.merge(task_type: 'type_2', guid: 'highest_task', priority: 6, status: 'paused'))
        TEF::Manager::Task.create(generic_stored_task_data.merge(task_type: 'type_3', guid: 'lowest_task', priority: 2))

        expect(TEF::Manager::Task.count).to eq(3)


        task = task_queue.pop([], [])


        expect(task.guid).to eq('middle_task')
      end

      it 'will only retrieve a task that is ready' do
        TEF::Manager::Task.create(generic_stored_task_data.merge(task_type: 'type_1', guid: 'middle_task', priority: 5, status: 'bar'))
        TEF::Manager::Task.create(generic_stored_task_data.merge(task_type: 'type_2', guid: 'highest_task', priority: 6, status: 'foo'))
        TEF::Manager::Task.create(generic_stored_task_data.merge(task_type: 'type_3', guid: 'lowest_task', priority: 2, status: 'ready'))

        task = task_queue.pop([], [])

        expect(task.guid).to eq('lowest_task')
      end

      it 'returns nil if no task matching the given criteria is found' do
        # Easiest way to ensure no matches is to not insert any tasks in the first place.
        expect(TEF::Manager::Task.count).to eq(0)

        task = task_queue.pop(nil, nil) #todo - really ought to have a better parameter format than this

        expect(task).to be_nil
      end

      it 'not providing worker types (i.e. nil) will be treated as if none were specified (i.e. an empty array)' do
        TEF::Manager::Task.create(generic_stored_task_data.merge(task_type: 'type_1', guid: 'middle_task', priority: 5))
        TEF::Manager::Task.create(generic_stored_task_data.merge(task_type: 'type_2', guid: 'highest_task', priority: 6))
        TEF::Manager::Task.create(generic_stored_task_data.merge(task_type: 'type_3', guid: 'lowest_task', priority: 2))

        expect(TEF::Manager::Task.count).to eq(3)


        task = task_queue.pop([], nil)


        expect(task.guid).to eq('highest_task')
      end

      it 'not providing unavailable resources (i.e. nil) will be treated as if none were specified (i.e. an empty array)' do
        TEF::Manager::Task.create(generic_stored_task_data.merge(task_type: 'type_1', guid: 'middle_task', priority: 5))
        TEF::Manager::TaskResource.create(task_id: 1, resource_name: 'res_1')
        TEF::Manager::TaskResource.create(task_id: 1, resource_name: 'res_2')
        TEF::Manager::Task.create(generic_stored_task_data.merge(task_type: 'type_2', guid: 'highest_task', priority: 6))
        TEF::Manager::TaskResource.create(task_id: 2, resource_name: 'res_1')
        TEF::Manager::TaskResource.create(task_id: 2, resource_name: 'res_3')
        TEF::Manager::Task.create(generic_stored_task_data.merge(task_type: 'type_3', guid: 'lowest_task', priority: 2))
        TEF::Manager::TaskResource.create(task_id: 3, resource_name: 'res_2')
        TEF::Manager::TaskResource.create(task_id: 3, resource_name: 'res_3')

        expect(TEF::Manager::Task.count).to eq(3)


        task = task_queue.pop(nil, [])


        expect(task.guid).to eq('highest_task')
      end

      it 'logs database errors when retrieving a task' do
        @old_method = TEF::Manager::Task.method(:where)
        TEF::Manager::Task.create(generic_stored_task_data)

        begin
          module TEF
            module Manager
              # Monkey patch ActiveRecord to throw the error that we need
              class Task
                def self.where(*args)
                  raise(TinyTds::Error, 'closed connection error')
                end
              end
            end
          end

          task = task_queue.pop(nil, nil)
        ensure
          # Making sure that the monkey patch doesn't escape this test and ruin the rest of the suite
          TEF::Manager::Task.define_singleton_method(@old_method.name, &@old_method)
        end

        expect(mock_logger).to have_received(:error)

        expect(task).to be_nil
      end
    end

  end
end
