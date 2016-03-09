require 'spec_helper'

describe 'Manager, Unit' do

  let(:clazz) { TEF::Manager::Manager }


  it 'is capable of consuming from message queues' do
    expect(clazz.ancestors).to include(Bunny::Consumer)
  end


  it_should_behave_like 'a strictly configured component'


  describe 'instance level' do

    let(:mock_logger) { create_mock_logger }
    let(:mock_dispatcher) { double('mock_dispatcher') }
    let(:mock_task_queue) { double('mock_task_queue') }
    let(:mock_worker_collective) { double('mock_worker_collective') }
    let(:mock_input_queue) { create_mock_queue }

    let(:configuration) { {
        in_queue: mock_input_queue,
        dispatcher: mock_dispatcher,
        task_queue: mock_task_queue,
        worker_collective: mock_worker_collective,
        logger: mock_logger
    } }

    let(:manager) { clazz.new(configuration) }


    it_should_behave_like 'a logged component, unit level'
    it_should_behave_like 'a responsive component, unit level', [:in_queue], {needs_started: true}


    it 'has an input queue' do
      expect(manager).to respond_to(:input_queue)
    end

    it 'will complain if not provided a with an input queue' do
      configuration.delete(:in_queue)

      expect { clazz.new(configuration) }.to raise_error(ArgumentError, /must have a/i)
    end

    it 'uses the given input queue' do
      configuration[:in_queue] = mock_input_queue

      manager = clazz.new(configuration)

      expect(manager.input_queue).to eq(mock_input_queue)
    end

    it 'has a dispatcher' do
      expect(manager).to respond_to(:dispatcher)
    end

    it 'will complain if not provided a with a dispatcher' do
      configuration.delete(:dispatcher)

      expect { clazz.new(configuration) }.to raise_error(ArgumentError, /must be provided/i)
    end

    it 'uses the given dispatcher' do
      configuration[:dispatcher] = mock_dispatcher

      manager = clazz.new(configuration)

      expect(manager.dispatcher).to eq(mock_dispatcher)
    end

    it 'has a task queue' do
      expect(manager).to respond_to(:task_queue)
    end

    it 'will complain if not provided a with a task queue' do
      configuration.delete(:task_queue)

      expect { clazz.new(configuration) }.to raise_error(ArgumentError, /must be provided/i)
    end

    it 'uses the given task queue' do
      configuration[:task_queue] = mock_task_queue

      manager = clazz.new(configuration)

      expect(manager.task_queue).to eq(mock_task_queue)
    end

    it 'has a worker collective' do
      expect(manager).to respond_to(:worker_collective)
    end

    it 'will complain if not provided a with a worker collective' do
      configuration.delete(:worker_collective)

      expect { clazz.new(configuration) }.to raise_error(ArgumentError, /must be provided/i)
    end

    it 'uses the given worker collective' do
      configuration[:worker_collective] = mock_worker_collective

      manager = clazz.new(configuration)

      expect(manager.worker_collective).to eq(mock_worker_collective)
    end

    it 'can be started' do
      expect(manager).to respond_to(:start)
    end

    it 'can be stopped' do
      expect(manager).to respond_to(:stop)
    end

    it 'has a state' do
      expect(manager).to respond_to(:state)
    end

    it 'has an initial state of starting' do
      expect(manager.state).to eq(:starting)
    end

    it 'has a dispatch interval' do
      expect(manager).to respond_to(:dispatch_interval)
    end

    it 'can be provided a dispatch interval when created' do
      configuration[:dispatch_interval] = 99
      manager = clazz.new(configuration)

      expect(manager.dispatch_interval).to eq(99)
    end

    it 'has a default dispatch interval of 10 if one is not provided' do
      configuration.delete(:dispatch_interval)
      manager = clazz.new(configuration)

      expect(manager.dispatch_interval).to eq(10)
    end

    it 'only accepts integers as dispatch intervals' do
      configuration[:dispatch_interval] = '99'

      expect { clazz.new(configuration) }.to raise_error(ArgumentError, /only.+integer/i)
    end


    describe 'setting manager state' do

      let(:set_state_command) { {type: 'set_state', data: 'paused'} }


      it 'can change its state' do
        expect(manager).to respond_to(:set_state)
      end

      it 'requires a new state to which it will be set' do
        expect(manager.method(:set_state).arity).to eq(1)
      end

      it 'can be set to a running state' do
        manager.set_state(:running)

        expect(manager.state).to eq(:running)
      end

      it 'can be set to a paused state' do
        manager.set_state(:paused)

        expect(manager.state).to eq(:paused)
      end

      it 'can be set to a stopped state' do
        manager.set_state(:stopped)

        expect(manager.state).to eq(:stopped)
      end

      it 'logs state changes' do
        manager.set_state(:running)
        expect(mock_logger).to have_received(:info).with('STATE_CHANGE|starting|running')
      end
    end

  end
end
