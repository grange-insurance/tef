require 'spec_helper'

describe 'WorkerCollective, Unit' do

  clazz = TEF::Manager::WorkerCollective

  it_should_behave_like 'a strictly configured component', clazz

  describe 'instance level' do

    before(:each) do
      @mock_logger = create_mock_logger
      @mock_control_queue = create_mock_queue
      @mock_resource_manager = double('mock resource manager')

      @options = {
          control_queue: @mock_control_queue,
          logger: @mock_logger,
          resource_manager: @mock_resource_manager
      }

      @worker_collective = clazz.new(@options)
    end

    it_should_behave_like 'a logged component, unit level' do
      let(:clazz) { clazz }
      let(:configuration) { @options }
    end

    it 'will complain if not provided a with a control queue' do
      @options.delete(:control_queue)

      expect { clazz.new(@options) }.to raise_error(ArgumentError, /must be provided/i)
    end

    it 'will complain if not provided a with a resource manager' do
      @options.delete(:resource_manager)

      expect { clazz.new(@options) }.to raise_error(ArgumentError, /must be provided/i)
    end

    #todo - fix the 'receive'/'have_received' mixup that may be present in other places
    # before tossing this negative test
    #     it 'does not change the progname on the logger' do
    #       expect(@mock_logger).not_to receive(:progname=)
    #     end

    it 'has workers' do
      expect(@worker_collective).to respond_to(:workers)
    end

    it 'starts with no workers' do
      expect(@worker_collective.workers).to be_empty
    end

    it 'can add a new worker' do
      expect(@worker_collective).to respond_to(:register_worker)
    end

    it 'requires a name, message queue, and worker data in order to add a worker' do
      expect(@worker_collective.method(:register_worker).arity).to eq(3)
    end

    it 'knows what types of workers have been added' do
      expect(@worker_collective).to respond_to(:known_worker_types)
    end

    it 'tracks which worker types are currently available' do
      expect(@worker_collective).to respond_to(:available_worker_types)
    end

    it 'can retrieve a worker' do
      expect(@worker_collective).to respond_to(:get_worker)
    end

    it 'can optionally retrieve a worker based on type' do
      expect(@worker_collective.method(:get_worker).arity).to eq(-1)
    end

    it 'has a control point that provides a data dump of all workers' do
      expect(@worker_collective).to respond_to(:control_get_workers)
    end

    it 'can optionally receive data on its data dump control point' do
      expect(@worker_collective.method(:control_get_workers).arity).to eq(-1)
    end

    it 'has a control point that updates the status of its workers' do
      expect(@worker_collective).to respond_to(:control_worker_status)
    end

    it 'requires worker data in order to control the status of a worker' do
      expect(@worker_collective.method(:control_worker_status).arity).to eq(1)
    end

    it 'knows whether or not any workers are available' do
      expect(@worker_collective).to respond_to(:available_workers?)
    end

    it 'has an update interval for the workers that it creates' do
      expect(@worker_collective).to respond_to(:worker_update_interval)
    end

    #todo - add this type of test to other classes (most of them are probably missing it)
    it 'can be provided with an update interval upon creation' do
      @options[:worker_update_interval] = 12345
      worker_collective = clazz.new(@options)

      expect(worker_collective.worker_update_interval).to eq(12345)
    end

    it 'has a default worker update interval of 30 seconds' do
      expect(@worker_collective.worker_update_interval).to eq(30)
    end

    it 'has an control queue' do
      expect(@worker_collective).to respond_to(:control_queue)
    end

    it 'subscribes to the control queue' do
      expect(@mock_control_queue).to have_received(:subscribe_with)
    end

    it 'can be provided with a resource manager upon creation' do
      @options[:resource_manager] = :a_resource_manager
      worker_collective = clazz.new(@options)

      expect(worker_collective.instance_variable_get(:@resource_manager)).to eq(:a_resource_manager)
    end

  end

end
