module TEF
  module Core

    class InnerComponent < Bunny::Consumer

      attr_reader :logger


      def initialize(options = {})
        validate_configuration_options(options)
        configure_self(options)

        # todo - test the ack flag being used
        super(@in_queue.channel, @in_queue, @in_queue.channel.generate_consumer_tag, false)
      end

      def start
        listen_for_messages
      end

      def stop
        # Just exists so the object knows how to respond. Should be overridden if anything needs to happen.
      end


      private


      def validate_configuration_options(options)
        # output_exchange isn't necessarily used, so it it not required
        raise(ArgumentError, 'Configuration options must have an :in_queue') unless options[:in_queue]
      end

      def configure_self(options)
        @in_queue = options[:in_queue]
        @output_exchange = options[:output_exchange]
        @logger = options.fetch(:logger, Logger.new($stdout))
      end

      def set_message_action(callback)
        self.on_delivery do |delivery_info, properties, payload|

          # Do whatever needs to be done in order to handle a message
          begin
            callback.call(delivery_info, properties, payload)
          rescue => e
            # Gracefully handle any problems
            @logger.error "There was a problem while handling the message: #{e.message}:#{e.backtrace}"
          end

          # Always ackknowledge the message
          @in_queue.channel.acknowledge(delivery_info.delivery_tag, false)
        end
      end

      def listen_for_messages
        # todo - find a way to test for blocking flag/behavior
        # Non-blocking is the default but passing it in anyway for clarity
        @in_queue.subscribe_with(self, block: false)
      end

    end
  end
end
