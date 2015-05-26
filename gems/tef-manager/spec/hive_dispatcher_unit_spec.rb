require 'spec_helper'
require 'json'
# require 'mock_publisher'
# require 'timers'

describe 'Dispatcher, Unit' do

  clazz = TEF::Manager::Dispatcher

  it_should_behave_like 'a strictly configured component', clazz


  describe 'instance level' do

    before(:each) do
      @mock_logger = create_mock_logger
      @mock_resource_manager = create_mock_resource_manager
      @fake_task = create_fake_task
      @mock_task = create_mock_task
      @mock_task_queue = create_mock_task_queue(@mock_task, nil)

      @mock_worker = create_mock_worker
      @mock_worker_collective = create_mock_worker_collective(@mock_worker)
      @mock_channel = create_mock_channel
      @mock_control_queue = create_mock_queue

      @options = {
          logger: @mock_logger,
          control_queue: @mock_control_queue,
          resource_manager: @mock_resource_manager,
          task_queue: @mock_task_queue,
          worker_collective: @mock_worker_collective,
      }

      @dispatcher = clazz.new(@options)
    end

    it_should_behave_like 'a logged component, unit level' do
      let(:clazz) { clazz }
      let(:configuration) { @options }
    end


    it 'can be started' do
      expect(@dispatcher).to respond_to(:start)
    end

    it 'can be stopped' do
      expect(@dispatcher).to respond_to(:stop)
    end

    it 'can dispatch tasks' do
      expect(@dispatcher).to respond_to(:dispatch_tasks)
    end

    it 'has a state' do
      expect(@dispatcher).to respond_to(:state)
    end

    it 'can change its state' do
      expect(@dispatcher).to respond_to(:state=)

      @dispatcher.state = 'foo'
      expect(@dispatcher.state).to eq('foo')
      @dispatcher.state = 'bar'
      expect(@dispatcher.state).to eq('bar')
    end

    it 'has an initial state of starting' do
      expect(@dispatcher.state).to eq(:starting)
    end

    it 'logs state changes' do
      @dispatcher.state = 'foo'
      expect(@mock_logger).to have_received(:info).with('STATE_CHANGE|starting|foo')
    end

    it 'has a control queue' do
      expect(@dispatcher).to respond_to(:control_queue)
    end

    it 'has a resource manager' do
      expect(@dispatcher).to respond_to(:resource_manager)
    end

    it 'has a task queue' do
      expect(@dispatcher).to respond_to(:task_queue)
    end

    it 'has a worker collective' do
      expect(@dispatcher).to respond_to(:worker_collective)
    end

    it 'has a dispatch interval' do
      expect(@dispatcher).to respond_to(:dispatch_interval)
    end

    it 'can be provided a dispatch interval when created' do
      @options[:dispatch_interval] = 99
      dispatcher = clazz.new(@options)

      expect(dispatcher.dispatch_interval).to eq(99)
    end

    it 'has a default dispatch interval of 10 if one is not provided' do
      @options.delete(:dispatch_interval)
      dispatcher = clazz.new(@options)

      expect(dispatcher.dispatch_interval).to eq(10)
    end

    it 'only accepts integers as dispatch intervals' do
      @options[:dispatch_interval] = '99'

      expect { clazz.new(@options) }.to raise_error(ArgumentError, /only.+integer/i)
    end


    describe 'initial setup' do

      it 'delegates task queue work to its provided task queue' do
        @options[:task_queue] = @mock_task_queue

        dispatcher = clazz.new(@options)

        expect(dispatcher.task_queue).to eq(@mock_task_queue)
      end

      it 'will complain if not provided a queue from which to get tasks' do
        @options.delete(:task_queue)

        expect { clazz.new(@options) }.to raise_error(ArgumentError, /must have/i)
      end

      it 'delegates control work to its provided control queue' do
        @options[:control_queue] = @mock_control_queue

        dispatcher = clazz.new(@options)

        expect(dispatcher.control_queue).to eq(@mock_control_queue)
      end

      it 'will complain if not provided a queue from which to get control messages' do
        @options.delete(:control_queue)

        expect { clazz.new(@options) }.to raise_error(ArgumentError, /must have/i)
      end

      it 'delegates worker collective work to its provided worker collective' do
        @options[:worker_collective] = @mock_worker_collective

        dispatcher = clazz.new(@options)

        expect(dispatcher.worker_collective).to eq(@mock_worker_collective)
      end

      it 'will complain if not provided a worker collective' do
        @options.delete(:worker_collective)

        expect { clazz.new(@options) }.to raise_error(ArgumentError, /must have/i)
      end

      it 'delegates resource manager work to its provided resource manager' do
        @options[:resource_manager] = @mock_resource_manager

        dispatcher = clazz.new(@options)

        expect(dispatcher.resource_manager).to eq(@mock_resource_manager)
      end

      it 'will complain if not provided a resource manager' do
        @options.delete(:resource_manager)

        expect { clazz.new(@options) }.to raise_error(ArgumentError, /must have/i)
      end

    end


    describe 'dispatching tasks' do

      it 'pulls from the task_queue when dispatching tasks' do
        @dispatcher.state = :running
        @dispatcher.dispatch_tasks

        expect(@mock_task_queue).to have_received(:pop).at_least(:once)
      end

      it 'continues to service the queue as long as there are workable tasks' do
        mock_task_queue = create_mock_task_queue(create_fake_task, create_fake_task, nil)
        @options[:task_queue] = mock_task_queue

        dispatcher = clazz.new(@options)
        dispatcher.state = :running
        dispatcher.dispatch_tasks

        expect(mock_task_queue).to have_received(:pop).exactly(3).times
      end

      it 'logs if there are no workable tasks found' do
        allow(@mock_task_queue).to receive(:pop).and_return(nil)

        @dispatcher.state = :running
        @dispatcher.dispatch_tasks

        expect(@mock_logger).to have_received(:info).with(/no.*tasks/i)
      end

      it 'does not consider a task to be workable if there are no workers' do
        allow(@mock_worker_collective).to receive(:available_workers?).and_return(false)
        @dispatcher.state = :running
        @dispatcher.dispatch_tasks

        expect(@mock_task_queue).not_to have_received(:pop)
      end

      it 'logs if there are no workers to dispatch tasks to' do
        allow(@mock_worker_collective).to receive(:available_workers?).and_return(false)

        @dispatcher.state = :running
        @dispatcher.dispatch_tasks

        expect(@mock_logger).to have_received(:info).with(/no.*workers/i)
      end

      it 'does not consider a task to be workable if there are not workers of the needed type available' do
        @dispatcher.state = :running
        @dispatcher.dispatch_tasks

        # todo - this test doesn't feel like it is sufficiently proving that what it is meant to test is really happening
        expect(@mock_worker_collective).to have_received(:available_worker_types).at_least(:once)
      end

      it 'logs which worker types are available' do
        allow(@mock_worker_collective).to receive(:available_worker_types).and_return(['type_1', 'type_2'])

        @dispatcher.state = :running
        @dispatcher.dispatch_tasks


        # todo - There has to be a better RSpec way to test this but the below doesn't
        # work so this long way is done instead.
        # expect(@mock_logger).to have_received(:debug).with(/worker types available: type_1, type_2/i)

        debug_messages = []
        expect(@mock_logger).to have_received(:debug).at_least(:once) do |message|
          debug_messages << message
        end

        expect(debug_messages).to include(/worker types available: type_1, type_2/i)
      end

      it 'does not consider a task to be workable if its needed resources are not available' do
        @dispatcher.state = :running
        @dispatcher.dispatch_tasks

        # todo - this test doesn't feel like it is sufficiently proving that what it is meant to test is really happening
        expect(@mock_resource_manager).to have_received(:unavailable_resources).at_least(:once)
      end

      it 'logs which resources are unavailable (unavailable resources)' do
        allow(@mock_resource_manager).to receive(:unavailable_resources).and_return(['foo', 'bar'])

        @dispatcher.state = :running
        @dispatcher.dispatch_tasks


        # todo - There has to be a better RSpec way to test this but the below doesn't
        # work so this long way is done instead.
        # expect(@mock_logger).to have_received(:debug).with(/unavailable resources: foo, bar/i)

        debug_messages = []
        expect(@mock_logger).to have_received(:debug).at_least(:once) do |message|
          debug_messages << message
        end

        expect(debug_messages).to include(/unavailable resources: foo, bar/i)
      end

      it 'logs which resources are unavailable (no unavailable resources)' do
        allow(@mock_resource_manager).to receive(:unavailable_resources).and_return([])

        @dispatcher.state = :running
        @dispatcher.dispatch_tasks


        # todo - There has to be a better RSpec way to test this but the below doesn't
        # work so this long way is done instead.
        # expect(@mock_logger).to have_received(:debug).with(/unavailable resources: foo, bar/i)

        debug_messages = []
        expect(@mock_logger).to have_received(:debug).at_least(:once) do |message|
          debug_messages << message
        end

        expect(debug_messages).to include(/all resources available/i)
      end

      # todo - this test kind of ties the previous two together to maybe finally prove the point but it still feels like we are guaranteeing the wrong thing/in the wrong place
      it 'passes the available worker types and unavailable resources to the task queue when dispatching tasks' do
        allow(@mock_resource_manager).to receive(:unavailable_resources).and_return(%w(res_1 res_2 res_3))
        allow(@mock_worker_collective).to receive(:available_worker_types).and_return(%w(type_1 type_2 type_3))

        @dispatcher.state = :running
        @dispatcher.dispatch_tasks

        expect(@mock_task_queue).to have_received(:pop).with(%w(res_1 res_2 res_3), %w(type_1 type_2 type_3)).at_least(:once)
      end

      it 'dispatches a task to a worker' do
        @dispatcher.state = :running
        @dispatcher.dispatch_tasks

        expect(@mock_worker).to have_received(:work)
      end

      it 'dispatched a task to the correct type of worker for the task' do
        allow(@mock_task).to receive(:task_type).and_return('type_x')

        @dispatcher.state = :running
        @dispatcher.dispatch_tasks

        # todo - this test doesn't feel like it is sufficiently proving that what it is meant to test is really happening
        expect(@mock_worker_collective).to have_received(:get_worker).with('type_x')
      end

      it 'logs successful dispatches to workers in a parseable manner' do
        @fake_task.task_type = 'type_x'
        @fake_task.guid = 'logger_test'
        allow(@mock_task_queue).to receive(:pop).and_return(@fake_task, nil)

        @dispatcher.state = :running
        @dispatcher.dispatch_tasks

        log_lines = "DISPATCH|#{@fake_task.task_type}|#{@fake_task.guid}|mock worker name"

        expect(@mock_logger).to have_received(:info).with(log_lines)
      end

      it 'will requeue a task when there is an error with the worker' do
        allow(@mock_worker).to receive(:work).and_return(false)

        @dispatcher.state = :running
        @dispatcher.dispatch_tasks

        expect(@mock_task_queue).to have_received(:push).with(@mock_task.to_h)
      end

      it 'logs failed dispatches to workers in a parseable manner' do
        @fake_task.task_type = 'type_x'
        @fake_task.guid = 'logger_test'
        allow(@mock_task_queue).to receive(:pop).and_return(@fake_task, nil)
        allow(@mock_worker).to receive(:work).and_return(false)

        @dispatcher.state = :running
        @dispatcher.dispatch_tasks

        expect(@mock_logger).to have_received(:error).with("DISPATCH_FAILED|#{@fake_task.task_type}|#{@fake_task.guid}|mock worker name")
      end

      it 'does not dispatch tasks unless it is running' do
        no_dispatch_states = [:paused, :stopped]

        no_dispatch_states.each do |state|
          @dispatcher.state = state
          @dispatcher.dispatch_tasks

          expect(@mock_worker).not_to have_received(:work)
        end

        @dispatcher.state = :running
        @dispatcher.dispatch_tasks

        expect(@mock_worker).to have_received(:work)
      end

      it 'logs if it is not dispatching due to its state' do
        @dispatcher.state = :non_runnning_state

        @dispatcher.dispatch_tasks

        expect(@mock_logger).to have_received(:info).with(/not.*dispatching.*#{@dispatcher.state}/i)
      end
    end


    describe 'control functionality' do

      before(:each) do
        @set_state_command = {type: 'set_state', data: 'paused'}
        @pause_suite_command = {type: 'pause_suite', data: 'suite_123456'}
        @stop_suite_command = {type: 'stop_suite', data: 'suite_123456'}
        @ready_suite_command = {type: 'ready_suite', data: 'suite_123456'}
      end


      describe 'setting dispatcher state' do

        it 'has a control point that can set the state of the dispatcher' do
          expect(@dispatcher).to respond_to(:control_set_state)
        end

        it 'requires state data in order to control the state of the dispatcher' do
          expect(@dispatcher.method(:control_set_state).arity).to eq(1)
        end

        it 'will complain if not provided with state data with which to set the state' do
          @set_state_command.delete(:data)

          expect { @dispatcher.control_set_state(@set_state_command) }.to raise_error(ArgumentError, /INVALID_JSON\|NO_DATA/i)
        end

        it 'will complain if given an invalid state' do
          @set_state_command[:data] = 'not an approved state'

          expect { @dispatcher.control_set_state(@set_state_command) }.to raise_error(ArgumentError, /INVALID_JSON\|INVALID_STATE\|#{@set_state_command[:data]}/i)
        end

        it 'updates the status of the dispatcher on a good status update' do
          @set_state_command[:data] = :paused

          @dispatcher.control_set_state(@set_state_command)

          expect(@dispatcher.state).to eq(:paused)
        end

      end

      describe 'suite pausing' do

        it 'has a control point that can pause a given suite' do
          expect(@dispatcher).to respond_to(:control_pause_suite)
        end

        it 'requires a suite guid in order to pause a suite' do
          expect(@dispatcher.method(:control_pause_suite).arity).to eq(1)
        end

        it 'will complain if not provided with guid data with which to pause a suite' do
          @pause_suite_command.delete(:data)

          expect { @dispatcher.control_pause_suite(@pause_suite_command) }.to raise_error(ArgumentError, /INVALID_JSON\|NO_DATA/i)
        end

      end

      describe 'suite readying' do

        it 'has a control point that can ready a given suite' do
          expect(@dispatcher).to respond_to(:control_ready_suite)
        end

        it 'requires a suite guid in order to ready a suite' do
          expect(@dispatcher.method(:control_ready_suite).arity).to eq(1)
        end

        it 'will complain if not provided with guid data with which to ready a suite' do
          @ready_suite_command.delete(:data)

          expect { @dispatcher.control_ready_suite(@ready_suite_command) }.to raise_error(ArgumentError, /INVALID_JSON\|NO_DATA/i)
        end

      end

      describe 'suite stopping' do

        it 'has a control point that can stop a given suite' do
          expect(@dispatcher).to respond_to(:control_stop_suite)
        end

        it 'requires a suite guid in order to stop a suite' do
          expect(@dispatcher.method(:control_stop_suite).arity).to eq(1)
        end

        it 'will complain if not provided with guid data with which to stop a suite' do
          @stop_suite_command.delete(:data)

          expect { @dispatcher.control_stop_suite(@stop_suite_command) }.to raise_error(ArgumentError, /INVALID_JSON\|NO_DATA/i)
        end

      end

    end

  end
end
