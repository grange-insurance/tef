require 'spec_helper'
require 'active_record'
require 'database_cleaner'

describe 'TaskQueue, Integration' do

  clazz = TEF::Manager::TaskQueue

  describe 'instance level' do
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
      @test_task = {type: "task", task_type: "type_1", guid: "guid1", priority: 5, resources: "pipe|delminated|list", task_data: "ew0KICAibWVzc2FnZSI6ICJIZWxsbyBXb3JsZCINCn0="}

      @mock_logger = create_mock_logger
      @mock_exchange = create_mock_exchange
      @mock_channel = create_mock_channel(@mock_exchange)
      @mock_input_queue = create_mock_queue

      @options = {
          logger: @mock_logger,
          input_queue: @mock_input_queue
      }

      @task_queue = clazz.new(@options)
    end

    after(:each) do
      DatabaseCleaner.clean
    end


    it_should_behave_like 'a logged component, integration level' do
      let(:clazz) { clazz }
      let(:configuration) { @options }
    end


    describe 'message handling' do

      it 'replies to replies to successful messages if requested' do
        properties = create_mock_properties(reply_to: 'some queue')
        input_queue = create_fake_publisher(@mock_channel)
        @options[:input_queue] = input_queue

        clazz.new(@options)
        input_queue.call(create_mock_delivery_info, properties, JSON.generate(@test_task))

        expect(@mock_exchange).to have_received(:publish).with('{"response":true}', {routing_key: properties.reply_to, correlation_id: properties.correlation_id})
      end

      it 'does not reply to successful messages if not requested' do
        properties = create_mock_properties(reply_to: nil)
        input_queue = create_fake_publisher(@mock_channel)
        @options[:input_queue] = input_queue

        clazz.new(@options)
        input_queue.call(create_mock_delivery_info, properties, JSON.generate(@test_task))

        expect(@mock_exchange).to_not have_received(:publish)
      end

    end

    describe 'task storing' do

      it 'storing a task into the queue returns true if successful' do
        input_queue = create_fake_publisher(create_mock_channel)
        @options[:input_queue] = input_queue

        task_queue = clazz.new(@options)

        expect(task_queue.push(@test_task)).to be true
      end

      it 'stores the tasks that it receives' do
        #todo - just let the publisher make its own channel if we don't want to have to provide one
        input_queue = create_fake_publisher(create_mock_channel)
        @options[:input_queue] = input_queue

        clazz.new(@options)
        input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))

        # Just here to help save debugging time if something goes wrong
        expect(@mock_logger).not_to have_received(:error)

        expect(TEF::Manager::Task.count).to eq(1)
      end

      it 'tasks are set to a ready state when stored' do
        input_queue = create_fake_publisher(create_mock_channel)
        @options[:input_queue] = input_queue

        clazz.new(@options)
        input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))

        expect(TEF::Manager::Task.first.status).to eq('ready')
      end

      it 'records the resources used by a received task' do
        input_queue = create_fake_publisher(create_mock_channel)
        @options[:input_queue] = input_queue
        @test_task[:resources] = 'res1|res2|res3'

        clazz.new(@options)
        input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))

        # Just here to help save debugging time if something goes wrong
        expect(@mock_logger).not_to have_received(:error)

        expect(TEF::Manager::TaskResource.count).to eq(3)
      end

      it 'logs when it queues a task that has no type' do
        input_queue = create_fake_publisher(create_mock_channel)
        @options[:input_queue] = input_queue
        @test_task.delete(:task_type)
        @test_task[:guid] = 'foo'

        clazz.new(@options)
        input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))

        # Just here to help save debugging time if something goes wrong
        expect(@mock_logger).not_to have_received(:error)

        expect(@mock_logger).to have_received(:warn).with(/task foo.*no task type.*#{Regexp.escape(@test_task.to_s)}/i)

        # Still stores it
        expect(TEF::Manager::Task.count).to eq(1)
      end
    end

    describe 'task retrieving' do

      it 'pulls the highest priority task from the queue' do
        input_queue = create_fake_publisher(create_mock_channel)
        @options[:input_queue] = input_queue


        task_queue = clazz.new(@options)

        # Loading up some tasks
        @test_task.merge!({task_type: 'type_1', guid: 'middle_task', priority: 5})
        input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))
        @test_task.merge!({task_type: 'type_2', guid: 'highest_task', priority: 6})
        input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))
        @test_task.merge!({task_type: 'type_3', guid: 'lowest_task', priority: 2})
        input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))


        # Just here to help save debugging time if something goes wrong
        expect(@mock_logger).not_to have_received(:error)
        expect(TEF::Manager::Task.count).to eq(3)

        task = task_queue.pop([], [])
        expect(task.guid).to eq('highest_task')
      end

      it 'only pulls tasks for which there are workers' do
        input_queue = create_fake_publisher(create_mock_channel)
        @options[:input_queue] = input_queue


        task_queue = clazz.new(@options)

        # Loading up some tasks
        @test_task.merge!({task_type: 'type_1', guid: 'middle_task', priority: 5})
        input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))
        @test_task.merge!({task_type: 'type_2', guid: 'highest_task', priority: 6})
        input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))
        @test_task.merge!({task_type: 'type_3', guid: 'lowest_task', priority: 2})
        input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))

        # Just here to help save debugging time if something goes wrong
        expect(@mock_logger).not_to have_received(:error)
        expect(TEF::Manager::Task.count).to eq(3)


        task = task_queue.pop(nil, ['type_3', 'type_4'])
        expect(task.guid).to eq('lowest_task')
      end

      # todo - Change this so that no worker types really means no worker types. 'All types' has no
      # meaning within the context of the framework
      it 'specifying no worker types (i.e. an empty array) will return all worker types' do
        input_queue = create_fake_publisher(create_mock_channel)
        @options[:input_queue] = input_queue


        task_queue = clazz.new(@options)

        # Loading up some tasks
        @test_task.merge!({task_type: 'type_1', guid: 'middle_task', priority: 5})
        input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))
        @test_task.merge!({task_type: 'type_2', guid: 'highest_task', priority: 6})
        input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))
        @test_task.merge!({task_type: 'type_3', guid: 'lowest_task', priority: 2})
        input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))

        # Just here to help save debugging time if something goes wrong
        expect(@mock_logger).not_to have_received(:error)
        expect(TEF::Manager::Task.count).to eq(3)


        task = task_queue.pop(nil, [])
        expect(task.guid).to eq('highest_task')
      end


      it 'only pulls tasks for which resources are available' do
        input_queue = create_fake_publisher(create_mock_channel)
        @options[:input_queue] = input_queue


        task_queue = clazz.new(@options)

        # Loading up some tasks
        @test_task.merge!({task_type: 'type_1', guid: 'middle_task', priority: 5, resources: 'res_1|res_2'})
        input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))
        @test_task.merge!({task_type: 'type_2', guid: 'highest_task', priority: 6, resources: 'res_1|res_3'})
        input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))
        @test_task.merge!({task_type: 'type_3', guid: 'lowest_task', priority: 2, resources: 'res_2|res_3'})
        input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))

        # Just here to help save debugging time if something goes wrong
        expect(@mock_logger).not_to have_received(:error)
        expect(TEF::Manager::Task.count).to eq(3)


        task = task_queue.pop(['res_3'], nil)
        expect(task.guid).to eq('middle_task')
      end

      it 'will not retrieve a task that has been dispatched' do
        input_queue = create_fake_publisher(create_mock_channel)
        @options[:input_queue] = input_queue


        task_queue = clazz.new(@options)

        # Loading up some tasks
        @test_task.merge!({guid: 'highest task', priority: 6})
        input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))

        task = TEF::Manager::Task.first
        task.dispatched = DateTime.now
        task.save

        @test_task.merge!({guid: 'middle_task', priority: 5})
        input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))
        @test_task.merge!({guid: 'lowest_task', priority: 2})
        input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))


        # Just here to help save debugging time if something goes wrong
        expect(@mock_logger).not_to have_received(:error)
        expect(TEF::Manager::Task.count).to eq(3)

        task = task_queue.pop([], [])
        expect(task.guid).to eq('middle_task')
      end

      #todo - DRY out all of the duplication in this section of testing

      it 'will not retrieve a task that has been paused' do
        input_queue = create_fake_publisher(create_mock_channel)
        @options[:input_queue] = input_queue


        task_queue = clazz.new(@options)

        # Loading up some tasks
        @test_task.merge!({guid: 'highest task', priority: 6})
        input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))

        task = TEF::Manager::Task.first
        task.status = 'paused'
        task.save

        @test_task.merge!({guid: 'middle_task', priority: 5})
        input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))
        @test_task.merge!({guid: 'lowest_task', priority: 2})
        input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))


        # Just here to help save debugging time if something goes wrong
        expect(@mock_logger).not_to have_received(:error)
        expect(TEF::Manager::Task.count).to eq(3)

        task = task_queue.pop([], [])
        expect(task.guid).to eq('middle_task')
      end

      it 'will only retrieve a task that is ready' do
        input_queue = create_fake_publisher(create_mock_channel)
        @options[:input_queue] = input_queue


        task_queue = clazz.new(@options)

        # Loading up some tasks
        @test_task.merge!({guid: 'highest task', priority: 6})
        input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))
        @test_task.merge!({guid: 'middle task', priority: 5})
        input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))
        @test_task.merge!({guid: 'lowest task', priority: 2})
        input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))

        task = TEF::Manager::Task.find_by(guid: 'highest task')
        task.status = 'foo'
        task.save
        task = TEF::Manager::Task.find_by(guid: 'middle task')
        task.status = 'bar'
        task.save
        task = TEF::Manager::Task.find_by(guid: 'lowest task')
        task.status = 'ready'
        task.save


        task = task_queue.pop([], [])
        expect(task.guid).to eq('lowest task')
      end

      it 'returns nil if no task matching the given criteria is found' do
        input_queue = create_fake_publisher(create_mock_channel)
        @options[:input_queue] = input_queue

        task_queue = clazz.new(@options)
        # Easiest way to ensure no matches is to not insert any tasks in the first place.
        expect(TEF::Manager::Task.count).to eq(0)

        task = task_queue.pop(nil, nil) #todo - really ought to have a better parameter format than this

        # Just here to help save debugging time if something goes wrong
        expect(@mock_logger).not_to have_received(:error)


        expect(task).to be_nil
      end

      it 'not providing worker types (i.e. nil) will be treated as if none were specified (i.e. an empty array)' do
        input_queue = create_fake_publisher(create_mock_channel)
        @options[:input_queue] = input_queue


        task_queue = clazz.new(@options)

        # Loading up some tasks
        @test_task.merge!({task_type: 'type_1', guid: 'middle_task', priority: 5})
        input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))
        @test_task.merge!({task_type: 'type_2', guid: 'highest_task', priority: 6})
        input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))
        @test_task.merge!({task_type: 'type_3', guid: 'lowest_task', priority: 2})
        input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))

        # Just here to help save debugging time if something goes wrong
        expect(@mock_logger).not_to have_received(:error)
        expect(TEF::Manager::Task.count).to eq(3)


        task = task_queue.pop([], nil)
        expect(task.guid).to eq('highest_task')
      end

      it 'not providing unavailable resources (i.e. nil) will be treated as if none were specified (i.e. an empty array)' do
        input_queue = create_fake_publisher(create_mock_channel)
        @options[:input_queue] = input_queue


        task_queue = clazz.new(@options)

        # Loading up some tasks
        @test_task.merge!({task_type: 'type_1', guid: 'middle_task', priority: 5, resources: 'res_1|res_2'})
        input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))
        @test_task.merge!({task_type: 'type_2', guid: 'highest_task', priority: 6, resources: 'res_1|res_3'})
        input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))
        @test_task.merge!({task_type: 'type_3', guid: 'lowest_task', priority: 2, resources: 'res_2|res_3'})
        input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))

        # Just here to help save debugging time if something goes wrong
        expect(@mock_logger).not_to have_received(:error)
        expect(TEF::Manager::Task.count).to eq(3)


        task = task_queue.pop(nil, [])
        expect(task.guid).to eq('highest_task')
      end

      it 'logs database errors when retrieving a task' do
        @old_method = TEF::Manager::Task.method(:where)
        input_queue = create_fake_publisher(create_mock_channel)
        @options[:input_queue] = input_queue


        task_queue = clazz.new(@options)
        input_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))

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

        expect(@mock_logger).to have_received(:error)
        expect(task).to be_nil
      end
    end

  end
end
