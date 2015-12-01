require 'socket'

module TEF
  module Worker
    class WorkNode < Core::TefComponent

      EXIT_CODE_FAILED_QUEUE = 3

      attr_reader :logger, :in_queue_name, :out_queue_name, :manager_queue_name, :worker_type, :root_location
      attr_accessor :name


      def initialize(options = {})
        super(options)

        env_var_name = 'TEF_WORK_NODE_ROOT_LOCATION'
        @root_location = options.fetch(:root_location, ENV[env_var_name])
        @logger.warn("A root location for the worker was not provided or set in the #{env_var_name} environmental variable") unless @root_location

        @worker = options.fetch(:worker_class, TEF::Worker::BaseWorker)
        @worker_type = options.fetch(:worker_type, 'generic')
        @queue_prefix = options.fetch(:queue_prefix, "tef.#{tef_env}")
        @worker_queue = options.fetch(:in_queue, "#{@queue_prefix}.worker.#{Socket.gethostname}.#{Process.pid}")
        @keeper_queue = options.fetch(:out_queue, "#{@queue_prefix}.keeper.#{@worker_type}")
        @manager_queue = options.fetch(:manager_queue, "#{@queue_prefix}.manager")
        @name = options.fetch(:name, "#{Socket.gethostname}.#{Process.pid}")

        @logger.info('Worker created.')
      end

      def start
        @logger.info('Starting worker node')

        super

        create_message_queues
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


      def create_message_queues
        @logger.debug('creating control queues')

        channel = @connection.create_channel

        begin
          @worker_queue = channel.queue(@worker_queue, :durable => true) if @worker_queue.is_a?(String)
          @in_queue_name = @worker_queue.name
          @logger.info "In queue: #{@in_queue_name} (channel #{channel.id})"

          @keeper_queue = channel.queue(@keeper_queue, :durable => true) if @keeper_queue.is_a?(String)
          @out_queue_name = @keeper_queue.name
          @logger.info "Out queue: #{@out_queue_name} (channel #{channel.id})"

          @manager_queue = channel.queue(@manager_queue, :durable => true) if @manager_queue.is_a?(String)
          @manager_queue_name = @manager_queue.name
          @logger.info "Manager queue: #{@manager_queue_name} (channel #{channel.id})"
        rescue => ex
          @logger.error("Failed to create control queues.  #{ex.message}")
          exit(EXIT_CODE_FAILED_QUEUE)
        end
      end

      def create_worker
        @logger.debug('creating worker')

        # todo - shouldn't the worker type be passed along here as well so that they always match?
        worker_options = {in_queue: @worker_queue,
                          out_queue: @keeper_queue,
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
