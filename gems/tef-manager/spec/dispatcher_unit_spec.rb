require 'spec_helper'
require 'json'
# require 'mock_publisher'
# require 'timers'

describe 'Dispatcher, Unit' do

  let(:clazz) { TEF::Manager::Dispatcher }

  it_should_behave_like 'a strictly configured component'


  describe 'instance level' do

    let(:mock_logger) { create_mock_logger }
    let(:mock_resource_manager) { create_mock_resource_manager }
    let(:fake_task) { create_fake_task }
    let(:mock_task) { create_mock_task }
    let(:mock_task_queue) { create_mock_task_queue([mock_task, nil]) }
    let(:mock_worker) { create_mock_worker }
    let(:mock_worker_collective) { create_mock_worker_collective(mock_worker) }

    let(:configuration) { {
        logger: mock_logger,
        resource_manager: mock_resource_manager,
        task_queue: mock_task_queue,
        worker_collective: mock_worker_collective,
    } }

    let(:dispatcher) { clazz.new(configuration) }


    it_should_behave_like 'a logged component, unit level'


    it 'can dispatch tasks' do
      expect(dispatcher).to respond_to(:dispatch_tasks)
    end

    it 'can pause a task suite' do
      expect(dispatcher).to respond_to(:pause_suite)
    end

    it 'requires a suite guid in order to pause a suite' do
      expect(dispatcher.method(:pause_suite).arity).to eq(1)
    end

    it 'can ready a task suite' do
      expect(dispatcher).to respond_to(:ready_suite)
    end

    it 'requires a suite guid in order to ready a suite' do
      expect(dispatcher.method(:ready_suite).arity).to eq(1)
    end

    it 'can stop a task suite' do
      expect(dispatcher).to respond_to(:stop_suite)
    end

    it 'requires a suite guid in order to stop a suite' do
      expect(dispatcher.method(:stop_suite).arity).to eq(1)
    end

    it 'has a resource manager' do
      expect(dispatcher).to respond_to(:resource_manager)
    end

    it 'has a task queue' do
      expect(dispatcher).to respond_to(:task_queue)
    end

    it 'has a worker collective' do
      expect(dispatcher).to respond_to(:worker_collective)
    end


    describe 'initial setup' do

      it 'delegates task queue work to its provided task queue' do
        configuration[:task_queue] = mock_task_queue

        dispatcher = clazz.new(configuration)

        expect(dispatcher.task_queue).to eq(mock_task_queue)
      end

      it 'will complain if not provided a queue from which to get tasks' do
        configuration.delete(:task_queue)

        expect { clazz.new(configuration) }.to raise_error(ArgumentError, /must have/i)
      end

      it 'delegates worker collective work to its provided worker collective' do
        configuration[:worker_collective] = mock_worker_collective

        dispatcher = clazz.new(configuration)

        expect(dispatcher.worker_collective).to eq(mock_worker_collective)
      end

      it 'will complain if not provided a worker collective' do
        configuration.delete(:worker_collective)

        expect { clazz.new(configuration) }.to raise_error(ArgumentError, /must have/i)
      end

      it 'delegates resource manager work to its provided resource manager' do
        configuration[:resource_manager] = mock_resource_manager

        dispatcher = clazz.new(configuration)

        expect(dispatcher.resource_manager).to eq(mock_resource_manager)
      end

      it 'will complain if not provided a resource manager' do
        configuration.delete(:resource_manager)

        expect { clazz.new(configuration) }.to raise_error(ArgumentError, /must have/i)
      end

    end


    describe 'dispatching tasks' do

      it 'pulls from the task_queue when dispatching tasks' do
        dispatcher.dispatch_tasks

        expect(mock_task_queue).to have_received(:pop).at_least(:once)
      end

      it 'continues to service the queue as long as there are workable tasks' do
        mock_task_queue = create_mock_task_queue([create_fake_task, create_fake_task, nil])
        configuration[:task_queue] = mock_task_queue

        dispatcher = clazz.new(configuration)
        dispatcher.dispatch_tasks

        expect(mock_task_queue).to have_received(:pop).exactly(3).times
      end

      it 'logs if there are no workable tasks found' do
        allow(mock_task_queue).to receive(:pop).and_return(nil)

        dispatcher.dispatch_tasks

        expect(mock_logger).to have_received(:info).with(/no.*tasks/i)
      end

      it 'does not consider a task to be workable if there are no workers' do
        allow(mock_worker_collective).to receive(:available_workers?).and_return(false)
        dispatcher.dispatch_tasks

        expect(mock_task_queue).not_to have_received(:pop)
      end

      it 'logs if there are no workers to dispatch tasks to' do
        allow(mock_worker_collective).to receive(:available_workers?).and_return(false)

        dispatcher.dispatch_tasks

        expect(mock_logger).to have_received(:info).with(/no.*workers/i)
      end

      it 'does not consider a task to be workable if there are not workers of the needed type available' do
        dispatcher.dispatch_tasks

        # todo - this test doesn't feel like it is sufficiently proving that what it is meant to test is really happening
        expect(mock_worker_collective).to have_received(:available_worker_types).at_least(:once)
      end

      it 'logs which worker types are available' do
        allow(mock_worker_collective).to receive(:available_worker_types).and_return(['type_1', 'type_2'])

        dispatcher.dispatch_tasks


        # todo - There has to be a better RSpec way to test this but the below doesn't
        # work so this long way is done instead.
        # expect(mock_logger).to have_received(:debug).with(/worker types available: type_1, type_2/i)

        debug_messages = []
        expect(mock_logger).to have_received(:debug).at_least(:once) do |message|
          debug_messages << message
        end

        expect(debug_messages).to include(/worker types available: type_1, type_2/i)
      end

      it 'does not consider a task to be workable if its needed resources are not available' do
        dispatcher.dispatch_tasks

        # todo - this test doesn't feel like it is sufficiently proving that what it is meant to test is really happening
        expect(mock_resource_manager).to have_received(:unavailable_resources).at_least(:once)
      end

      it 'logs which resources are unavailable (unavailable resources)' do
        allow(mock_resource_manager).to receive(:unavailable_resources).and_return(['foo', 'bar'])

        dispatcher.dispatch_tasks


        # todo - There has to be a better RSpec way to test this but the below doesn't
        # work so this long way is done instead.
        # expect(mock_logger).to have_received(:debug).with(/unavailable resources: foo, bar/i)

        debug_messages = []
        expect(mock_logger).to have_received(:debug).at_least(:once) do |message|
          debug_messages << message
        end

        expect(debug_messages).to include(/unavailable resources: foo, bar/i)
      end

      it 'logs which resources are unavailable (no unavailable resources)' do
        allow(mock_resource_manager).to receive(:unavailable_resources).and_return([])

        dispatcher.dispatch_tasks


        # todo - There has to be a better RSpec way to test this but the below doesn't
        # work so this long way is done instead.
        # expect(mock_logger).to have_received(:debug).with(/unavailable resources: foo, bar/i)

        debug_messages = []
        expect(mock_logger).to have_received(:debug).at_least(:once) do |message|
          debug_messages << message
        end

        expect(debug_messages).to include(/all resources available/i)
      end

      # todo - this test kind of ties the previous two together to maybe finally prove the point but it still feels like we are guaranteeing the wrong thing/in the wrong place
      it 'passes the available worker types and unavailable resources to the task queue when dispatching tasks' do
        allow(mock_resource_manager).to receive(:unavailable_resources).and_return(%w(res_1 res_2 res_3))
        allow(mock_worker_collective).to receive(:available_worker_types).and_return(%w(type_1 type_2 type_3))

        dispatcher.dispatch_tasks

        expect(mock_task_queue).to have_received(:pop).with(%w(res_1 res_2 res_3), %w(type_1 type_2 type_3)).at_least(:once)
      end

      it 'dispatches a task to a worker' do
        dispatcher.dispatch_tasks

        expect(mock_worker).to have_received(:work)
      end

      it 'dispatched a task to the correct type of worker for the task' do
        allow(mock_task).to receive(:task_type).and_return('type_x')

        dispatcher.dispatch_tasks

        # todo - this test doesn't feel like it is sufficiently proving that what it is meant to test is really happening
        expect(mock_worker_collective).to have_received(:get_worker).with('type_x')
      end

      it 'logs successful dispatches to workers in a parseable manner' do
        fake_task.task_type = 'type_x'
        fake_task.guid = 'logger_test'
        allow(mock_task_queue).to receive(:pop).and_return(fake_task, nil)

        dispatcher.dispatch_tasks

        log_lines = "DISPATCH|#{fake_task.task_type}|#{fake_task.guid}|mock worker name"

        expect(mock_logger).to have_received(:info).with(log_lines)
      end

      it 'will requeue a task when there is an error with the worker' do
        allow(mock_worker).to receive(:work).and_return(false)

        dispatcher.dispatch_tasks

        expect(mock_task_queue).to have_received(:push).with(mock_task.to_h)
      end

      it 'logs failed dispatches to workers in a parseable manner' do
        fake_task.task_type = 'type_x'
        fake_task.guid = 'logger_test'
        allow(mock_task_queue).to receive(:pop).and_return(fake_task, nil)
        allow(mock_worker).to receive(:work).and_return(false)

        dispatcher.dispatch_tasks

        expect(mock_logger).to have_received(:error).with("DISPATCH_FAILED|#{fake_task.task_type}|#{fake_task.guid}|mock worker name")
      end

    end

  end
end
