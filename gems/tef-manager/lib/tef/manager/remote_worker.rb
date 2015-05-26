require 'json'
require 'active_support/core_ext'


module TEF
  module Manager
    # Client logic for talking to workers
    class RemoteWorker

      attr_reader :name, :work_queue, :task, :last_update_time, :type, :update_interval, :logger

      def initialize(options)
        validate_options(options)
        configure_self(options)

        self.status = :idle
      end

      def release_task
        @logger.debug "Release task #{@task.guid}"
        @resource_manager.remove_ref(task.resource_names)
        @task.dispatched = nil
        @task.save
        @task = nil
      end

      def delete_task
        the_task = @task
        release_task
        @logger.debug "Delete task #{the_task.guid}"
        the_task.destroy
      end

      def status=(new_status)
        @last_update_time = DateTime.now

        # todo- this no-op functionality could use a test
        return if @internal_status == new_status

        @logger.debug "RemoteWorker status change from #{@internal_status} to #{new_status}"

        release_task if @internal_status == :dispatched && new_status != :working # Aborted, never started working
        release_task if @internal_status == :working && new_status != :task_complete # Aborted, didn't finish working
        delete_task if @internal_status == :working && new_status == :task_complete # Successful

        @internal_status = new_status
      end

      def seconds_since_last_update
        # todo - not really testing this right now
        # Math below is to calculate the number of seconds
        # between two DateTimes
        ((DateTime.now - @last_update_time) * 24 * 60 * 60).ceil
      end

      def time_limit
        return @task.time_limit unless (@task.nil? || @task.time_limit.nil?)
        @time_limit
      end

      def status
        unless @internal_status == :idle
          return :stalled if  seconds_since_last_update > time_limit
        end

        return :missing if seconds_since_last_update > @update_interval

        @internal_status
      end

      def work(task)
        return false unless @resource_manager.add_ref(task.resource_names)

        @task = task
        self.status = :dispatched
        task.dispatched = Time.now
        task.save

        @work_queue.publish(JSON.generate(task.to_h))

        true
      end

      def to_h
        {
            name: @name,
            work_queue: @work_queue.name,
            status: status,
            task: @task.nil? ? nil : @task.to_h
        }
      end


      private


      def validate_options(options)
        raise(ArgumentError, 'A :name must be provided.') unless options[:name]
        raise(ArgumentError, 'A :work_queue must be provided.') unless options[:work_queue]
        raise(ArgumentError, 'A :type must be provided.') unless options[:type]
        raise(ArgumentError, 'A :resource_manager must be provided.') unless options[:resource_manager]
      end

      def configure_self(options)
        @logger = options.fetch(:logger, Logger.new($stdout))
        @name = options[:name]
        @type = options[:type]
        @update_interval = options.fetch(:update_interval, 30)
        @time_limit = options.fetch(:time_limit, 600)
        @work_queue = options[:work_queue]
        @resource_manager = options[:resource_manager]
      end

    end
  end
end
