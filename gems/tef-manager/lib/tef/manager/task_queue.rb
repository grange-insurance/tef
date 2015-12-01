require 'logger'
require 'json'


module TEF
  module Manager
    # The task queue supplies tasks to the dispatcher.
    class TaskQueue

      attr_reader :logger


      def initialize(options)
        @logger = options.fetch(:logger, Logger.new($stdout))
      end

      def push(task_hash)
        unless task_hash[:task_type]
          warning = "Task #{task_hash[:guid]} has no task type: #{task_hash}"
          @logger.warn warning
        end

        task = Task.new
        task.load_hash(task_hash)
        task.status = 'ready'

        # Caller will catch save exceptions
        task.save

        # Assume success if it didn't explode
        true
      end

      def pop(unavailable_resources, worker_types)
        unavailable_resources ||= []
        worker_types ||= []
        task = nil

        begin
          ActiveRecord::Base.connection_pool.with_connection do

            type_query = 'task_type IN (:worker_types)'
            resource_query = "id NOT IN (SELECT task_id FROM #{TaskResource.table_name} WHERE resource_name IN(:unavailable_resources))"
            paused_exclusion_query = "((status <> 'paused') OR (status is null))"
            ready_only_query = "(status= 'ready')"

            needed_queries = ['dispatched IS NULL']
            needed_queries << ready_only_query
            needed_queries << paused_exclusion_query
            needed_queries << type_query unless worker_types.empty?
            needed_queries << resource_query unless unavailable_resources.empty?

            tasks = Task.where(needed_queries.join(' AND '), {worker_types: worker_types, unavailable_resources: unavailable_resources}).order(priority: :desc)
            task = tasks.first
          end
        rescue => exception
          # TODO: Handle DB errors gracefully
          error = "POP_FAILED|#{exception.message}|#{exception.backtrace}"
          @logger.error error
        end

        task
      end

    end
  end
end
