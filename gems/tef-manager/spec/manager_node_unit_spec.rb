require 'spec_helper'
require 'rspec/mocks/standalone'


describe 'ManagerNode, Unit' do

  let(:clazz) { TEF::Manager::ManagerNode }

  let(:mock_logger) { create_mock_logger }
  let(:mock_task_queue) { create_mock_task_queue }
  let(:mock_task_queue_class) { create_mock_task_queue_class(mock_task_queue) }
  let(:mock_worker_collective) { create_mock_worker_collective }
  let(:mock_worker_collective_class) { create_mock_worker_collective_class(mock_worker_collective) }
  let(:mock_resource_manager) { create_mock_resource_manager }
  let(:mock_resource_manager_class) { create_mock_resource_manager_class(mock_resource_manager) }
  let(:mock_dispatcher) { create_mock_dispatcher }
  let(:mock_dispatcher_class) { create_mock_dispatcher_class(mock_dispatcher) }
  let(:mock_manager) { create_mock_manager }
  let(:mock_manager_class) { create_mock_manager_class(mock_manager) }

  let(:configuration) { {in_queue: create_mock_queue,
                         resource_manager_class: create_mock_resource_manager_class,
                         manager_class: mock_manager_class,
                         logger: mock_logger
  } }

  it_should_behave_like 'a loosely configured component'
  it_should_behave_like 'a service component, unit level'
  it_should_behave_like 'a receiving component, unit level', [:in_queue]
  it_should_behave_like 'a logged component, unit level'
  it_should_behave_like 'a wrapper component, unit level', [:in_queue]


  describe 'initial setup' do

    let!(:manager_node) { clazz.new(configuration) }

    it 'sets a special program name for its logger' do
      expect(mock_logger).to have_received(:progname=)
    end

    it 'has a default message queue' do
      configuration.delete(:in_queue)

      manager_node = clazz.new(configuration)
      expect(manager_node.instance_variable_get(:@in_queue)).to_not be_nil
    end

    #todo - add this test to other components that use prefixes
    it 'has a default queue prefix that is based on an environmental variable' do
      env_var = 'TEF_ENV'
      old_env = ENV[env_var]

      begin
        ENV[env_var] = 'foo'
        configuration.delete(:queue_prefix)

        manager_node = clazz.new(configuration)

        expect(manager_node.instance_variable_get(:@name_prefix)).to eq('tef.foo')
      ensure
        ENV[env_var] = old_env
      end

    end

    it 'can be provided with an interval time for its worker collective upon creation' do
      configuration[:worker_update_interval] = 12345
      manager_node = clazz.new(configuration)

      expect(manager_node.instance_variable_get(:@worker_update_interval)).to eq(12345)
    end

    it 'has a default interval time of 30 seconds for its worker collective' do
      expect(manager_node.instance_variable_get(:@worker_update_interval)).to eq(30)
    end

  end

  # todo - This uses a real object and therefore it is an integration test. Move it to the correct spec file.
  it 'uses its update interval when creating a worker collective' do
    configuration[:worker_update_interval] = 12345
    manager_node = clazz.new(configuration)

    begin
      manager_node.start

      expect(manager_node.instance_variable_get(:@worker_collective).worker_update_interval).to eq(12345)
    ensure
      manager_node.stop
    end
  end

  it 'uses its task queue class for creating a task queue' do
    configuration[:task_queue_class] = mock_task_queue_class
    manager_node = clazz.new(configuration)

    begin
      manager_node.start

      expect(mock_task_queue_class).to have_received(:new)
    ensure
      manager_node.stop
    end
  end

  it 'uses its dispatcher class for creating a dispatcher' do
    configuration[:dispatcher_class] = mock_dispatcher_class
    manager_node = clazz.new(configuration)

    begin
      manager_node.start

      expect(mock_dispatcher_class).to have_received(:new)
    ensure
      manager_node.stop
    end
  end

  it 'uses its worker collective class for creating a worker collective' do
    configuration[:worker_collective_class] = mock_worker_collective_class
    manager_node = clazz.new(configuration)

    begin
      manager_node.start

      expect(mock_worker_collective_class).to have_received(:new)
    ensure
      manager_node.stop
    end
  end

  it 'uses its resource manager class for creating a resource manager' do
    configuration[:resource_manager_class] = mock_resource_manager_class
    manager_node = clazz.new(configuration)

    begin
      manager_node.start

      expect(mock_resource_manager_class).to have_received(:new)
    ensure
      manager_node.stop
    end
  end

  it 'uses its manager class for creating a manager' do
    configuration[:manager_class] = mock_manager_class
    manager_node = clazz.new(configuration)

    begin
      manager_node.start

      expect(mock_manager_class).to have_received(:new)
    ensure
      manager_node.stop
    end
  end

  it 'starts its manager when it is started' do
    configuration[:manager_class] = mock_manager_class
    manager_node = clazz.new(configuration)

    begin
      manager_node.start

      expect(mock_manager).to have_received(:start)
    ensure
      manager_node.stop
    end
  end

  it 'stops its manager when it is stopped' do
    configuration[:manager_class] = mock_manager_class
    manager_node = clazz.new(configuration)

    begin
      manager_node.start
      manager_node.stop

      expect(mock_manager).to have_received(:stop)
    ensure
      manager_node.stop
    end
  end

end
