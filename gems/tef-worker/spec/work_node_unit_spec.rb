require 'spec_helper'
require 'rspec/mocks/standalone'


def default_options
  {
      logger: create_mock_logger,
      in_queue: create_mock_queue,
      out_queue: create_mock_queue,
      manager_queue: create_mock_queue
  }
end


describe 'WorkNode, Unit' do

  clazz = TEF::Worker::WorkNode


  it_should_behave_like 'a loosely configured component', clazz


  # todo - Even though there are defaults for most things, if they are actually using those defaults
  # instead of mocks then these are really integration tests. The above likely applies to a lot of tests
  # for these framework. Go check and deal with it all at once.

  it_should_behave_like 'a service component, unit level' do
    let(:clazz) { clazz }
    let(:configuration) { default_options }
  end

  it_should_behave_like 'a receiving component, unit level', clazz, default_options, [:in_queue]
  it_should_behave_like 'a sending component, unit level', clazz, default_options, [:out_queue, :manager_queue]

  it_should_behave_like 'a logged component, unit level' do
    let(:clazz) { clazz }
    let(:configuration) { default_options }
  end

  it_should_behave_like 'a rooted component, unit level' do
    let(:clazz) { clazz }
    let(:configuration) { default_options }
  end


  describe 'instance level' do

    before(:each) do
      @mock_worker = double('mock worker')
      allow(@mock_worker).to receive(:start)
      allow(@mock_worker).to receive(:stop)
      @mock_worker_class = double('mock worker class')
      allow(@mock_worker_class).to receive(:new).and_return(@mock_worker)

      @options = default_options
      @work_node = clazz.new(@options)
    end


    it 'uses its worker class for creating a worker' do
      @options[:worker_class] = @mock_worker_class
      work_node = clazz.new(@options)

      begin
        work_node.start

        expect(@mock_worker_class).to have_received(:new)
      ensure
        work_node.stop
      end
    end

    it 'starts its worker when it is started' do
      @options[:worker_class] = @mock_worker_class
      work_node = clazz.new(@options)

      begin
        work_node.start

        expect(@mock_worker).to have_received(:start)
      ensure
        work_node.stop
      end
    end

    it 'stops its worker when it is stopped' do
      @options[:worker_class] = @mock_worker_class
      work_node = clazz.new(@options)

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
      @options[:worker_type] = 'some work node type'
      work_node = clazz.new(@options)

      expect(work_node.worker_type).to eq('some work node type')
    end

    it 'defaults to being a generic worker' do
      @options.delete(:worker_type)
      work_node = clazz.new(@options)

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
      @options[:name] = 'foo'
      work_node = clazz.new(@options)

      expect(work_node.name).to eq('foo')
    end

    it 'logs a warning if a root location cannot be determined upon creation' do
      env_var = 'TEF_WORK_NODE_ROOT_LOCATION'
      old_env = ENV[env_var]

      logger = create_mock_logger
      @options[:logger] = logger

      begin
        @options.delete(:root_location)
        ENV[env_var] = nil

        clazz.new(@options)

        expect(logger).to have_received(:warn).with(/root location.*not/)
      ensure
        ENV[env_var] = old_env
      end
    end

  end
end
