require 'spec_helper'
require 'rspec/mocks/standalone'


def default_options
  {
      dispatcher_queue: create_mock_queue,
      control_queue: create_mock_queue,
      resource_manager_class: create_mock_resource_manager_class,
      logger: create_mock_logger
  }
end


describe 'ManagerNode, Unit' do

  clazz = TEF::Manager::ManagerNode


  it_should_behave_like 'a loosely configured component', clazz

  it_should_behave_like 'a service component, unit level' do
    let(:clazz) { clazz }
    let(:configuration) { default_options }
  end

  it_should_behave_like 'a receiving component, unit level', clazz, default_options, [:task_queue, :dispatcher_queue, :worker_queue]

  it_should_behave_like 'a logged component, unit level' do
    let(:clazz) { clazz }
    let(:configuration) { default_options }
  end


  before(:each) do
    @mock_logger = create_mock_logger
    @mock_task_queue = double('mock task queue')
    @mock_worker_collective = double('mock worker collective')

    @mock_task_queue_class = double('mock task queue class')
    allow(@mock_task_queue_class).to receive(:new).and_return(@mock_task_queue)

    @mock_resource_manager_class = create_mock_resource_manager_class

    @mock_worker_collective_class = double('mock worker collective class')
    allow(@mock_worker_collective_class).to receive(:new).and_return(@mock_worker_collective)

    @mock_dispatcher = double('mock dispatcher')
    allow(@mock_dispatcher).to receive(:name)
    allow(@mock_dispatcher).to receive(:start)
    allow(@mock_dispatcher).to receive(:stop)

    @mock_dispatcher_class = double('mock dispatcher class')
    allow(@mock_dispatcher_class).to receive(:new).and_return(@mock_dispatcher)

    @mock_dispatcher_queue = create_mock_queue

    @options = default_options
    @options[:dispatcher_queue] = @mock_dispatcher_queue
    @options[:resource_manager_class] = @mock_resource_manager_class
    @options[:logger] = @mock_logger

    @manager = clazz.new(@options)
  end


  describe 'initial setup' do

    it 'sets a special program name for its logger' do
      expect(@mock_logger).to have_received(:progname=)
    end

    it 'has a default task queue' do
      @options.delete(:task_queue)

      manager = clazz.new(@options)
      expect(manager.instance_variable_get(:@task_queues_queue)).to_not be_nil
    end

    it 'has a default dispatcher queue' do
      @options.delete(:dispatcher_queue)

      manager = clazz.new(@options)
      expect(manager.instance_variable_get(:@dispatcher_queue)).to_not be_nil
    end

    it 'has a default worker queue' do
      @options.delete(:worker_queue)

      manager = clazz.new(@options)
      expect(manager.instance_variable_get(:@worker_queue)).to_not be_nil
    end

    #todo - add this test to other components that use prefixes
    it 'has a default queue prefix that is based on an environmental variable' do
      env_var = 'TEF_ENV'
      old_env = ENV[env_var]

      begin
        ENV[env_var] = 'foo'
        @options.delete(:queue_prefix)

        manager = clazz.new(@options)

        expect(manager.instance_variable_get(:@queue_prefix)).to eq('tef.foo')
      ensure
        ENV[env_var] = old_env
      end

    end

    it 'can be provided with an interval time for its worker collective upon creation' do
      @options[:worker_update_interval] = 12345
      manager = clazz.new(@options)

      expect(manager.instance_variable_get(:@worker_update_interval)).to eq(12345)
    end

    it 'has a default interval time of 30 seconds for its worker collective' do
      expect(@manager.instance_variable_get(:@worker_update_interval)).to eq(30)
    end

  end

  it 'uses its update interval when creating a worker collective' do
    @options[:worker_update_interval] = 12345
    manager = clazz.new(@options)

    begin
      manager.start

      expect(manager.instance_variable_get(:@worker_collective).worker_update_interval).to eq(12345)
    ensure
      manager.stop
    end
  end

  it 'uses its task queue class for creating a task queue' do
    @options[:task_queue_class] = @mock_task_queue_class
    manager = clazz.new(@options)

    begin
      manager.start

      expect(@mock_task_queue_class).to have_received(:new)
    ensure
      manager.stop
    end
  end

  it 'uses its dispatcher class for creating a dispatcher' do
    @options[:dispatcher_class] = @mock_dispatcher_class
    manager = clazz.new(@options)

    begin
      manager.start

      expect(@mock_dispatcher_class).to have_received(:new)
    ensure
      manager.stop
    end
  end

  it 'uses its worker collective class for creating a worker collective' do
    @options[:worker_collective_class] = @mock_worker_collective_class
    manager = clazz.new(@options)

    begin
      manager.start

      expect(@mock_worker_collective_class).to have_received(:new)
    ensure
      manager.stop
    end
  end

  it 'uses its resource manager class for creating a resource manager' do
    @options[:resource_manager_class] = @mock_resource_manager_class
    manager = clazz.new(@options)

    begin
      manager.start

      expect(@mock_resource_manager_class).to have_received(:new)
    ensure
      manager.stop
    end
  end

  it 'starts its dispatcher when it is started' do
    @options[:dispatcher_class] = @mock_dispatcher_class
    manager_node = clazz.new(@options)

    begin
      manager_node.start

      expect(@mock_dispatcher).to have_received(:start)
    ensure
      manager_node.stop
    end
  end

  it 'stops its dispatcher when it is stopped' do
    @options[:dispatcher_class] = @mock_dispatcher_class
    manager_node = clazz.new(@options)

    begin
      manager_node.start
      manager_node.stop

      expect(@mock_dispatcher).to have_received(:stop)
    ensure
      manager_node.stop
    end
  end

end
