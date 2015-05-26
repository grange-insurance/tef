require 'spec_helper'
require 'active_record'
require 'rspec/mocks/standalone'


def default_options
  {
      dispatcher_queue: create_mock_queue,
      control_queue: create_mock_queue,
      resource_manager_class: create_mock_resource_manager_class,
      logger: create_mock_logger
  }
end


describe 'ManagerNode, Integration' do

  clazz = TEF::Manager::ManagerNode

  it_should_behave_like 'a logged component, integration level' do
    let(:clazz) { clazz }
    let(:configuration) { default_options }
  end

  it_should_behave_like 'a service component, integration level' do
    let(:clazz) { clazz }
    let(:configuration) { default_options }
  end

  it_should_behave_like 'a receiving component, integration level', clazz, default_options, [:task_queue, :dispatcher_queue, :worker_queue]


  before(:each) do
    @mock_resource_manager_class = create_mock_resource_manager_class
    @mock_worker_collective_class = create_mock_worker_collective_class

    @options = default_options

    @manager = clazz.new(@options)
  end


  it 'defaults to a basic task queue class if one is not provided' do
    @options.delete(:task_queue_class)
    manager = clazz.new(@options)

    expect(manager.instance_variable_get(:@task_queue)).to eq(TEF::Manager::TaskQueue)
  end

  it 'defaults to a basic dispatcher class if one is not provided' do
    @options.delete(:dispatcher_class)
    manager = clazz.new(@options)

    expect(manager.instance_variable_get(:@dispatcher)).to eq(TEF::Manager::Dispatcher)
  end

  it 'defaults to a basic worker collective class if one is not provided' do
    @options.delete(:worker_collective_class)
    manager = clazz.new(@options)

    expect(manager.instance_variable_get(:@worker_collective)).to eq(TEF::Manager::WorkerCollective)
  end

  it 'defaults to a basic resource manager class if one is not provided' do
    @options.delete(:resource_manager_class)
    manager = clazz.new(@options)

    expect(manager.instance_variable_get(:@resource_manager)).to eq(ResMan::Manager)
  end

  it 'uses its own logging object when creating its task queue' do
    mock_logger = create_mock_logger
    @options[:logger] = mock_logger

    manager = clazz.new(@options)

    begin
      manager.start

      expect(manager.instance_variable_get(:@task_queue).logger).to eq(mock_logger)
    ensure
      manager.stop
    end
  end

  it 'uses its own logging object when creating its dispatcher' do
    mock_logger = create_mock_logger
    @options[:logger] = mock_logger

    manager = clazz.new(@options)

    begin
      manager.start

      expect(manager.instance_variable_get(:@dispatcher).logger).to eq(mock_logger)
    ensure
      manager.stop
    end
  end

  it 'uses its own logging object when creating its worker collective' do
    mock_logger = create_mock_logger
    @options[:logger] = mock_logger

    manager = clazz.new(@options)

    begin
      manager.start

      expect(manager.instance_variable_get(:@worker_collective).logger).to eq(mock_logger)
    ensure
      manager.stop
    end
  end

  it 'uses its own worker collective object when creating its dispatcher' do
    @options[:worker_collective_class] = @mock_worker_collective_class

    manager = clazz.new(@options)

    begin
      manager.start
      # todo - check out other delegation/child creation tests for proper eq/be matcher
      expect(manager.instance_variable_get(:@dispatcher).worker_collective).to be(manager.instance_variable_get(:@worker_collective))
    ensure
      manager.stop
    end
  end

  it 'uses its own resource manager object when creating its dispatcher' do
    @options[:resource_manager_class] = @mock_resource_manager_class

    manager = clazz.new(@options)

    begin
      manager.start
      # todo - check out other delegation/child creation tests for proper eq/be matcher
      expect(manager.instance_variable_get(:@dispatcher).resource_manager).to be(manager.instance_variable_get(:@resource_manager))
    ensure
      manager.stop
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
        @manager.start
        expect { TEF::Manager::Task.count }.to_not raise_error
      ensure
        @manager.stop
      end
    end

    it 'disconnects from its database when it stops' do
      begin
        @manager.start
        expect { TEF::Manager::Task.count }.to_not raise_error

        @manager.stop
        expect { TEF::Manager::Task.count }.to raise_error(ActiveRecord::ConnectionNotEstablished)
      ensure
        @manager.stop
      end
    end

  end

end
