require 'spec_helper'

describe 'WorkerCollective, Unit' do

  let(:clazz) { TEF::Manager::WorkerCollective }

  it_should_behave_like 'a strictly configured component'

  describe 'instance level' do

    let(:mock_logger) { create_mock_logger }
    let(:mock_resource_manager) { double('mock resource manager') }

    let(:configuration) { {logger: mock_logger,
                           resource_manager: mock_resource_manager} }

    let(:worker_collective) { clazz.new(configuration) }

    it_should_behave_like 'a logged component, unit level'


    it 'will complain if not provided a with a resource manager' do
      configuration.delete(:resource_manager)

      expect { clazz.new(configuration) }.to raise_error(ArgumentError, /must be provided/i)
    end

    #todo - fix the 'receive'/'have_received' mixup that may be present in other places
    # before tossing this negative test
    #     it 'does not change the progname on the logger' do
    #       expect(@mock_logger).not_to receive(:progname=)
    #     end

    it 'has workers' do
      expect(worker_collective).to respond_to(:workers)
    end

    it 'starts with no workers' do
      expect(worker_collective.workers).to be_empty
    end

    it 'can add a new worker' do
      expect(worker_collective).to respond_to(:register_worker)
    end

    it 'requires a name, message queue, and worker data in order to add a worker' do
      expect(worker_collective.method(:register_worker).arity).to eq(3)
    end

    it 'knows what types of workers have been added' do
      expect(worker_collective).to respond_to(:known_worker_types)
    end

    it 'tracks which worker types are currently available' do
      expect(worker_collective).to respond_to(:available_worker_types)
    end

    it 'can retrieve a worker' do
      expect(worker_collective).to respond_to(:get_worker)
    end

    it 'can optionally retrieve a worker based on type' do
      expect(worker_collective.method(:get_worker).arity).to eq(-1)
    end

    it 'can get a data dump of all workers' do
      expect(worker_collective).to respond_to(:get_workers)
    end

    # todo - why?
    it 'can optionally receive data on its data dump control point' do
      expect(worker_collective.method(:get_workers).arity).to eq(-1)
    end

    it 'can set the status of a worker' do
      expect(worker_collective).to respond_to(:set_worker_status)
    end

    it 'requires worker data in order to set the status of a worker' do
      expect(worker_collective.method(:set_worker_status).arity).to eq(1)
    end

    it 'knows whether or not any workers are available' do
      expect(worker_collective).to respond_to(:available_workers?)
    end

    it 'has an update interval for the workers that it creates' do
      expect(worker_collective).to respond_to(:worker_update_interval)
    end

    #todo - add this type of test to other classes (most of them are probably missing it)
    it 'can be provided with an update interval upon creation' do
      configuration[:worker_update_interval] = 12345
      worker_collective = clazz.new(configuration)

      expect(worker_collective.worker_update_interval).to eq(12345)
    end

    it 'has a default worker update interval of 30 seconds' do
      expect(worker_collective.worker_update_interval).to eq(30)
    end

    it 'can be provided with a resource manager upon creation' do
      configuration[:resource_manager] = :a_resource_manager
      worker_collective = clazz.new(configuration)

      expect(worker_collective.instance_variable_get(:@resource_manager)).to eq(:a_resource_manager)
    end

  end

end
