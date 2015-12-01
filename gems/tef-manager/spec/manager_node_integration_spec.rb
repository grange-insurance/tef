require 'spec_helper'
require 'active_record'
require 'rspec/mocks/standalone'


describe 'ManagerNode, Integration' do


  let(:clazz) { TEF::Manager::ManagerNode }
  let(:configuration) { {input_queue: create_mock_queue,
                         resource_manager_class: create_mock_resource_manager_class,
                         logger: create_mock_logger} }


  describe 'common manager node behavior' do
    it_should_behave_like 'a logged component, integration level'
    it_should_behave_like 'a service component, integration level', [:manager_queue]
    it_should_behave_like 'a receiving component, integration level', [:manager_queue]
    it_should_behave_like 'a wrapper component, integration level', [:manager_queue]
  end

  describe 'unique manager node behavior' do

    let(:mock_resource_manager_class) { create_mock_resource_manager_class }
    let(:mock_worker_collective_class) { create_mock_worker_collective_class }
    let(:manager_node) { clazz.new(configuration) }


    it 'defaults to a basic manager class if one is not provided' do
      configuration.delete(:manager_class)
      manager_node = clazz.new(configuration)

      expect(manager_node.instance_variable_get(:@manager)).to eq(TEF::Manager::Manager)
    end

    it 'defaults to a basic task queue class if one is not provided' do
      configuration.delete(:task_queue_class)
      manager_node = clazz.new(configuration)

      expect(manager_node.instance_variable_get(:@task_queue)).to eq(TEF::Manager::TaskQueue)
    end

    it 'defaults to a basic dispatcher class if one is not provided' do
      configuration.delete(:dispatcher_class)
      manager_node = clazz.new(configuration)

      expect(manager_node.instance_variable_get(:@dispatcher)).to eq(TEF::Manager::Dispatcher)
    end

    it 'defaults to a basic worker collective class if one is not provided' do
      configuration.delete(:worker_collective_class)
      manager_node = clazz.new(configuration)

      expect(manager_node.instance_variable_get(:@worker_collective)).to eq(TEF::Manager::WorkerCollective)
    end

    it 'defaults to a basic resource manager class if one is not provided' do
      configuration.delete(:resource_manager_class)
      manager_node = clazz.new(configuration)

      expect(manager_node.instance_variable_get(:@resource_manager)).to eq(ResMan::Manager)
    end

    it 'uses its own logging object when creating its task queue' do
      mock_logger = create_mock_logger
      configuration[:logger] = mock_logger

      manager_node = clazz.new(configuration)

      begin
        manager_node.start

        expect(manager_node.instance_variable_get(:@task_queue).logger).to eq(mock_logger)
      ensure
        manager_node.stop
      end
    end

    it 'uses its own logging object when creating its manager' do
      mock_logger = create_mock_logger
      configuration[:logger] = mock_logger

      manager_node = clazz.new(configuration)

      begin
        manager_node.start

        expect(manager_node.instance_variable_get(:@manager).logger).to eq(mock_logger)
      ensure
        manager_node.stop
      end
    end

    it 'uses its own logging object when creating its dispatcher' do
      mock_logger = create_mock_logger
      configuration[:logger] = mock_logger

      manager_node = clazz.new(configuration)

      begin
        manager_node.start

        expect(manager_node.instance_variable_get(:@dispatcher).logger).to eq(mock_logger)
      ensure
        manager_node.stop
      end
    end

    it 'uses its own logging object when creating its worker collective' do
      mock_logger = create_mock_logger
      configuration[:logger] = mock_logger

      manager_node = clazz.new(configuration)

      begin
        manager_node.start

        expect(manager_node.instance_variable_get(:@worker_collective).logger).to eq(mock_logger)
      ensure
        manager_node.stop
      end
    end

    it 'uses its own worker collective object when creating its dispatcher' do
      configuration[:worker_collective_class] = mock_worker_collective_class

      manager_node = clazz.new(configuration)

      begin
        manager_node.start
        # todo - check out other delegation/child creation tests for proper eq/be matcher
        expect(manager_node.instance_variable_get(:@dispatcher).worker_collective).to be(manager_node.instance_variable_get(:@worker_collective))
      ensure
        manager_node.stop
      end
    end

    it 'uses its own resource manager object when creating its dispatcher' do
      configuration[:resource_manager_class] = mock_resource_manager_class

      manager_node = clazz.new(configuration)

      begin
        manager_node.start
        # todo - check out other delegation/child creation tests for proper eq/be matcher
        expect(manager_node.instance_variable_get(:@dispatcher).resource_manager).to be(manager_node.instance_variable_get(:@resource_manager))
      ensure
        manager_node.stop
      end
    end


    describe 'database connections' do

      before(:each) do
        ActiveRecord::Base.remove_connection
        ActiveRecord::Base.table_name_prefix = "tef_#{tef_env}_"
      end

      it 'connects to its database when it starts' do
        expect { TEF::Manager::Task.count }.to raise_error(ActiveRecord::ConnectionNotEstablished)

        begin
          manager_node.start
          expect { TEF::Manager::Task.count }.to_not raise_error
        ensure
          manager_node.stop
        end
      end

      it 'disconnects from its database when it stops' do
        begin
          manager_node.start
          expect { TEF::Manager::Task.count }.to_not raise_error

          manager_node.stop
          expect { TEF::Manager::Task.count }.to raise_error(ActiveRecord::ConnectionNotEstablished)
        ensure
          manager_node.stop
        end
      end

    end

  end

end
