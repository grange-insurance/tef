module TEF
  module Manager
    # The collection of workers.
    class WorkerCollective

      attr_reader :logger, :workers, :worker_update_interval


      def initialize(options)
        validate_options(options)
        configure_self(options)
      end

      def set_worker_status(worker_data)
        queue_name  = worker_data[:exchange_name]
        name        = worker_data[:name]
        status      = worker_data[:status]

        if queue_name.nil?
          error = "CONTROL_FAILED|PARSE_JSON|MISSING_EXCHANGE_NAME|#{name}"
          logger.error(error)
          return false
        end

        if name.nil?
          logger.warn "CONTROL_WARN|PARSE_JSON|MISSING_NAME|#{queue_name}"
          return false
        end

        if status.nil?
          error = "CONTROL_FAILED|PARSE_JSON|MISSING_STATUS|#{name}"
          logger.error(error)
          return false
        end

        # todo - Maybe not do #to_sym. Test as needed.
        if status.to_sym == :offline
          @workers.delete(name)
          logger.info "CONTROL_SUCCESS|WORKER_OFFLINE|#{name}"
          return true
        end

        # todo - add testing for this logging/remove it
        logger.debug("received worker status of #{status} from #{name}")
        worker = @workers[name]

        # todo - Maybe not do #to_sym. Test as needed.
        #        This is a symbol because this is pretty much only
        #        used for comparisons and symbol compares are much faster
        worker.status = status.to_sym

        true
      end

      def register_worker(name, message_queue, data)
        worker_type = data[:worker_type]

        # todo - add testing for this logging/remove it
        logger.info("registering new #{worker_type} worker named #{name} listening on #{message_queue.name}")
        # todo - Dependency injection opportunity right here
        @workers[name] = RemoteWorker.new(name: name, work_queue: message_queue, type: worker_type, update_interval: @worker_update_interval, resource_manager: @resource_manager)

        # Just here for clarity
        @workers[name]
      end

      def get_workers(_data = nil)
        @workers.values.map(&:to_h)
      end

      def get_worker(specific_type = nil)
        @workers.values.select { |worker| (worker.status == :idle) && (specific_type ? worker.type == specific_type : true) }.first
      end

      def available_workers?
        @workers.values.any? { |worker| worker.status == :idle }
      end

      def known_worker_types
        @workers.values.map(&:type).uniq
      end

      def available_worker_types
        known_worker_types.select do |worker_type|
          @workers.values.any? { |worker| (worker.status == :idle) && (worker.type == worker_type) }
        end
      end


      private


      def validate_options(options)
        raise(ArgumentError, 'A :resource_manager must be provided.') unless options[:resource_manager]
      end

      def configure_self(options)
        @workers                = {}
        @logger                 = options.fetch(:logger, Logger.new($stdout))
        @worker_update_interval = options.fetch(:worker_update_interval, 30)
        @resource_manager       = options[:resource_manager]
      end

    end
  end
end
