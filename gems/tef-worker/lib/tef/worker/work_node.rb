require 'socket'

module TEF
  module Worker
    class WorkNode < Core::OuterComponent


      attr_reader :manager_queue_name, :worker_type, :root_location
      attr_accessor :name


      def initialize(options = {})
        super

        @logger.info('Worker created.')
      end

      def start
        @logger.info('Starting worker node')

        super

        create_worker
        @worker.start

        @logger.info('Start complete')
      end

      def stop
        @logger.info('Stopping worker node')

        @worker.stop if @worker.respond_to?(:stop)
        super

        @logger.info('Stop complete')
      end


      private


      def configure_self(options)
        super

        env_var_name = 'TEF_WORK_NODE_ROOT_LOCATION'
        @root_location = options.fetch(:root_location, ENV[env_var_name])
        @logger.warn("A root location for the worker was not provided or set in the #{env_var_name} environmental variable") unless @root_location

        @worker = options.fetch(:worker_class, TEF::Worker::BaseWorker)
        @worker_type = options.fetch(:worker_type, 'generic')
        @name_prefix = options.fetch(:name_prefix, "tef.#{tef_env}")
        @in_queue = options.fetch(:in_queue, "#{@name_prefix}.worker.#{Socket.gethostname}.#{Process.pid}")
        @output_exchange = options.fetch(:output_exchange, "#{@name_prefix}.worker_generated_messages")
        @manager_queue = options.fetch(:manager_queue, "#{@name_prefix}.manager")
        @name = options.fetch(:name, "#{Socket.gethostname}.#{Process.pid}")
      end


      def create_message_destinations
        super

        channel = @connection.create_channel

        begin
          @manager_queue = channel.queue(@manager_queue, :durable => true) if @manager_queue.is_a?(String)
          @manager_queue_name = @manager_queue.name
          @logger.info "Manager queue: #{@manager_queue_name} (channel #{channel.id})"
        rescue => ex
          @logger.error("Failed to create message destinations.  #{ex.message}")
          exit(EXIT_CODE_FAILED_QUEUE)
        end
      end

      def create_worker
        @logger.debug('creating worker')

        # todo - shouldn't the worker type be passed along here as well so that they always match?
        worker_options = {in_queue: @in_queue,
                          output_exchange: @output_exchange,
                          manager_queue: @manager_queue,
                          logger: @logger,
                          root_location: @root_location,
                          name: @name
        }

        @worker = @worker.new(worker_options)
      end

    end
  end
end
