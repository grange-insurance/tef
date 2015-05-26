require 'workers'
require 'bunny'

module TEF
  module Manager
    # The brains of the operation, dispatches tasks to the worker
    class Dispatcher < Bunny::Consumer

      attr_reader :logger, :control_queue, :resource_manager, :task_queue, :worker_collective, :state, :dispatch_interval

      include TEF::WithControlQueue

      def initialize(options)
        configure_self(options)
        validate_configuration_options(options)

        # todo - test the ack flag being used
        super(@control_queue.channel, @control_queue, @control_queue.channel.generate_consumer_tag, false)

        self.state = :starting
      end

      def state=(new_state)
        #todo - maybe some better logging when state is nil (such as when it is set for the first time)
        @logger.info "STATE_CHANGE|#{@state}|#{new_state}"
        @state = new_state
      end


      def start
        #todo - more testing here
        init_control(@control_queue)

        self.state = :running

        set_dispatch_loop
      end

      def stop
        @dispatch_timer.cancel if @dispatch_timer

        self.state = :stopped
      end


      def dispatch_tasks
        unless @state == :running
          @logger.info "Not dispatching tasks while state == #{@state}"
          return
        end

        task = next_workable_task
        @logger.info 'No workable tasks to dispatch' if task.nil?

        until task.nil?
          worker = @worker_collective.get_worker(task.task_type)

          @logger.debug "Attempting to dispatch #{task.task_type} task #{task.guid} to #{worker.name}"

          if worker.work(task)
            @logger.info "DISPATCH|#{task.task_type}|#{task.guid}|#{worker.name}"
          else
            @logger.error "DISPATCH_FAILED|#{task.task_type}|#{task.guid}|#{worker.name}"
            @task_queue.push(task.to_h)
          end

          task = next_workable_task
        end
      end

      def next_workable_task
        unless @worker_collective.available_workers?
          @logger.info('No available workers of any type.')
          return
        end

        worker_types = @worker_collective.available_worker_types
        @logger.debug("Worker types available: #{worker_types.join(", ")}")

        unavailable_resources = @resource_manager.unavailable_resources

        if unavailable_resources.empty?
          @logger.debug('All resources available.')
        else
          @logger.debug("Unavailable resources: #{unavailable_resources.join(", ")}")
        end

        task = @task_queue.pop(unavailable_resources, worker_types)

        task
      end

      def control_set_state(command)
        valid_states = [:running, :paused, :stopped]

        data = command[:data]

        raise(ArgumentError, 'INVALID_JSON|NO_DATA') unless data

        #todo - Again with the #to_sym...
        data = data.to_sym

        raise(ArgumentError, "INVALID_JSON|INVALID_STATE|#{data}") unless valid_states.include?(data)

        self.state = data
      end

      def control_pause_suite(command)
        data = command[:data]
        raise(ArgumentError, 'INVALID_JSON|NO_DATA') unless data

        @logger.info("Pausing task suite #{data}")
        tasks = TEF::Manager::Task.where(suite_guid: data)
        @logger.warn("No tasks found for suite #{data}") if tasks.empty?

        tasks.update_all(status: 'paused')
      end

      def control_ready_suite(command)
        data = command[:data]
        raise(ArgumentError, 'INVALID_JSON|NO_DATA') unless data

        @logger.info("Readying task suite #{data}")
        tasks = TEF::Manager::Task.where(suite_guid: data)
        @logger.warn("No tasks found for suite #{data}") if tasks.empty?

        tasks.update_all(status: 'ready')
      end

      def control_stop_suite(command)
        data = command[:data]
        raise(ArgumentError, 'INVALID_JSON|NO_DATA') unless data

        @logger.info("Stopping task suite #{data}")
        tasks = TEF::Manager::Task.where(suite_guid: data)
        @logger.warn("No tasks found for suite #{data}") if tasks.empty?

        tasks.delete_all
      end

      def validate_configuration_options(options)
        raise(ArgumentError, 'Configuration options must have a :task_queue') unless options[:task_queue]
        raise(ArgumentError, 'Configuration options must have a :control_queue') unless options[:control_queue]
        raise(ArgumentError, 'Configuration options must have a :worker_collective') unless options[:worker_collective]
        raise(ArgumentError, 'Configuration options must have a :resource_manager') unless options[:resource_manager]
        raise(ArgumentError, ":dispatch_interval can only be an integer. Got #{options[:dispatch_interval].class}") unless @dispatch_interval.is_a?(Integer)
      end

      def configure_self(options)
        @logger = options.fetch(:logger, Logger.new($stdout))
        @resource_manager = options[:resource_manager]
        @task_queue = options[:task_queue]
        @worker_collective = options[:worker_collective]
        @dispatch_interval = options.fetch(:dispatch_interval, 10)
        @control_queue = options[:control_queue]
      end

      def set_dispatch_loop
        @dispatch_timer = Workers::PeriodicTimer.new(dispatch_interval) do
          # todo - probably need to add some auto-stopping in case the dispatcher gets killed without #stop-ing
          dispatch_tasks
        end
      end


      # Pay no attention to the man behind the curtain
      private :configure_self, :validate_configuration_options, :next_workable_task, :set_dispatch_loop

    end
  end
end
