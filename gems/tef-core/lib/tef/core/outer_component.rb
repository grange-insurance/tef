module TEF
  module Core
    class OuterComponent

      EXIT_CODE_NO_URL = 1
      EXIT_CODE_FAILED_RABBIT = 2
      EXIT_CODE_FAILED_QUEUE = 3


      # todo - expose queue and exchange objects
      attr_reader :logger, :in_queue_name, :output_exchange_name


      def initialize(options)
        configure_self(options)
      end

      def start
        connect_rabbit
        create_message_destinations
      end

      # todo - Does this actually stop created consumers from living on in Rabbit?
      def stop
        @logger.info("Stopping #{self.class}...")
        @connection.stop if @connection
        @logger.info("#{self.class} stopped.")
      end


      private


      def configure_self(options)
        @logger = options.fetch(:logger, Logger.new($stdout))
        @in_queue = options[:in_queue]
        @output_exchange = options[:output_exchange]
      end


      def connect_rabbit
        if bunny_url.nil?
          @logger.error "Missing environment variable #{bunny_env_name}.  Cannot connect to RabbitMQ"
          exit(EXIT_CODE_NO_URL)
        end

        begin
          # TODO - could do more testing around the format of the url from environmental variable
          connection_options= {
              host: bunny_url.match(/\/\/(.*):\d+$/)[1],
              port: bunny_url.match(/:(\d+)$/)[1]
          }

          connection_options[:username] = bunny_username if bunny_username
          connection_options[:password] = bunny_password if bunny_password
          @logger.debug "connection options: #{connection_options}"

          # todo - Not sure why auto-reconnection still works (i.e. the relevant test passes). It
          # wasn't working without this before...
          #@connection = Bunny.new(host: host, port: port, recover_from_connection_close: true)

          # Todo - Not much way to check what options are used when connecting since we can't pass a mock in for this
          @connection = Bunny.new(connection_options)

          @connection.start

        rescue => ex
          @logger.error "Failed to connect to RabbitMQ\n#{ex.message}\n#{ex.backtrace}"
          exit(EXIT_CODE_FAILED_RABBIT)
        end
      end

      def create_message_destinations
        @logger.debug('creating message endpoints')

        begin
          channel = @connection.create_channel

          if @in_queue
            @in_queue = channel.queue(@in_queue, :durable => true) if @in_queue.is_a?(String)
            @in_queue_name = @in_queue.name
            @logger.info "In queue: #{@in_queue_name} (channel #{channel.id})"
          end

          if @output_exchange
            # todo - test that the exchange created is a topical exchange
            @output_exchange = channel.topic(@output_exchange, :durable => true) if @output_exchange.is_a?(String)
            @output_exchange_name = @output_exchange.name
            @logger.info "Output exchange: #{@output_exchange_name} (channel #{channel.id})"
          end

        rescue => ex
          @logger.error("Failed to create message destinations.  #{ex.message}")
          exit(EXIT_CODE_FAILED_QUEUE)
        end
      end

      def bunny_url
        ENV[bunny_env_name]
      end

      def bunny_username
        ENV[bunny_env_user]
      end

      def bunny_password
        ENV[bunny_env_password]
      end

      def bunny_env_name
        "TEF_AMQP_URL_#{tef_env.upcase}"
      end

      def bunny_env_user
        "TEF_AMQP_USER_#{tef_env.upcase}"
      end

      def bunny_env_password
        "TEF_AMQP_PASSWORD_#{tef_env.upcase}"
      end

      def tef_env
        ENV['TEF_ENV'] != nil ? ENV['TEF_ENV'].downcase : 'dev'
      end

    end
  end
end
