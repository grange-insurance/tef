require 'workers'
require 'bunny'


module TEF
  module Manager
    # The brains of the operation, dispatches tasks to the worker
    class Dispatcher

      attr_reader :logger, :resource_manager, :task_queue, :worker_collective


      def initialize(options)
        validate_configuration_options(options)
        configure_self(options)
      end

      def dispatch_tasks
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

      def pause_suite(suite_guid)
        @logger.info("Pausing task suite #{suite_guid}")
        tasks = TEF::Manager::Task.where(suite_guid: suite_guid)
        @logger.warn("No tasks found for suite #{suite_guid}") if tasks.empty?

        tasks.update_all(status: 'paused')
      end

      def ready_suite(suite_guid)
        @logger.info("Readying task suite #{suite_guid}")
        tasks = TEF::Manager::Task.where(suite_guid: suite_guid)
        @logger.warn("No tasks found for suite #{suite_guid}") if tasks.empty?

        tasks.update_all(status: 'ready')
      end

      def stop_suite(suite_guid)
        @logger.info("Stopping task suite #{suite_guid}")
        tasks = TEF::Manager::Task.where(suite_guid: suite_guid)
        @logger.warn("No tasks found for suite #{suite_guid}") if tasks.empty?

        tasks.delete_all
      end

      def validate_configuration_options(options)
        raise(ArgumentError, 'Configuration options must have a :worker_collective') unless options[:worker_collective]
        raise(ArgumentError, 'Configuration options must have a :resource_manager') unless options[:resource_manager]
        raise(ArgumentError, 'Configuration options must have a :task_queue') unless options[:task_queue]
      end

      def configure_self(options)
        @logger = options.fetch(:logger, Logger.new($stdout))
        @resource_manager = options[:resource_manager]
        @task_queue = options[:task_queue]
        @worker_collective = options[:worker_collective]
        @dispatch_interval = options.fetch(:dispatch_interval, 10)
        @control_queue = options[:control_queue]
      end


      # Pay no attention to the man behind the curtain
      private :configure_self, :validate_configuration_options, :next_workable_task

    end
  end
end
