require 'spec_helper'
require 'rspec/mocks/standalone'


describe 'WorkNode, Unit' do

  let(:clazz) { TEF::Worker::WorkNode }

  let(:mock_logger) { create_mock_logger }
  let(:mock_in_queue) { create_mock_queue }
  let(:mock_out_queue) { create_mock_queue }
  let(:mock_manager_queue) { create_mock_queue }

  let(:configuration) { {logger: mock_logger,
                         in_queue: mock_in_queue,
                         out_queue: mock_out_queue,
                         manager_queue: mock_manager_queue} }


  # todo - Even though there are defaults for most things, if they are actually using those defaults
  # instead of mocks then these are really integration tests. The above likely applies to a lot of tests
  # for these framework. Go check and deal with it all at once.

  it_should_behave_like 'a loosely configured component'
  it_should_behave_like 'a service component, unit level'
  it_should_behave_like 'a receiving component, unit level', [:in_queue]
  it_should_behave_like 'a sending component, unit level', [:out_queue, :manager_queue]
  it_should_behave_like 'a logged component, unit level'
  it_should_behave_like 'a rooted component, unit level'
  it_should_behave_like 'a wrapper component, unit level', [:in_queue, :out_queue, :manager_queue]


  describe 'instance level' do

    # todo - finish #let-ifying these
    before(:each) do
      @mock_worker = double('mock worker')
      allow(@mock_worker).to receive(:start)
      allow(@mock_worker).to receive(:stop)
      @mock_worker_class = double('mock worker class')
      allow(@mock_worker_class).to receive(:new).and_return(@mock_worker)

      @work_node = clazz.new(configuration)
    end


    it 'uses its worker class for creating a worker' do
      configuration[:worker_class] = @mock_worker_class
      work_node = clazz.new(configuration)

      begin
        work_node.start

        expect(@mock_worker_class).to have_received(:new)
      ensure
        work_node.stop
      end
    end

    it 'starts its worker when it is started' do
      configuration[:worker_class] = @mock_worker_class
      work_node = clazz.new(configuration)

      begin
        work_node.start

        expect(@mock_worker).to have_received(:start)
      ensure
        work_node.stop
      end
    end

    it 'stops its worker when it is stopped' do
      configuration[:worker_class] = @mock_worker_class
      work_node = clazz.new(configuration)

      begin
        work_node.start
        work_node.stop

        expect(@mock_worker).to have_received(:stop)
      ensure
        work_node.stop
      end
    end

    it 'has a worker type' do
      expect(@work_node).to respond_to(:worker_type)
    end

    it 'can be provided a worker type when created' do
      configuration[:worker_type] = 'some work node type'
      work_node = clazz.new(configuration)

      expect(work_node.worker_type).to eq('some work node type')
    end

    it 'defaults to being a generic worker' do
      configuration.delete(:worker_type)
      work_node = clazz.new(configuration)

      expect(work_node.worker_type).to eq('generic')
    end

    it 'has a name' do
      expect(@work_node).to respond_to(:name)
    end

    it 'can change its name' do
      expect(@work_node).to respond_to(:name=)

      @work_node.name = :some_name
      expect(@work_node.name).to eq(:some_name)
      @work_node.name = :some_other_name
      expect(@work_node.name).to eq(:some_other_name)
    end

    it 'starts with a default name' do
      expect(@work_node.name).to_not be_nil
    end

    it 'can be provided a name when created' do
      configuration[:name] = 'foo'
      work_node = clazz.new(configuration)

      expect(work_node.name).to eq('foo')
    end

    it 'logs a warning if a root location cannot be determined upon creation' do
      env_var = 'TEF_WORK_NODE_ROOT_LOCATION'
      old_env = ENV[env_var]

      logger = create_mock_logger
      configuration[:logger] = logger

      begin
        configuration.delete(:root_location)
        ENV[env_var] = nil

        clazz.new(configuration)

        expect(logger).to have_received(:warn).with(/root location.*not/)
      ensure
        ENV[env_var] = old_env
      end
    end

  end
end
