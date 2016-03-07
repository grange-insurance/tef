require 'tef/core'

module TEF
  module Keeper
    class Keeper < Core::OuterComponent


      attr_reader :keeper_type


      def initialize(options)
        super

        raise(ArgumentError, 'You must include a :callback in the options hash') unless options.has_key? :callback
        @task_callback = options[:callback]
      end

      # Keeper internal state doesn't look like it gets used for much. Can possibly get rid of.
      #      def state=(new_state)
      #        @logger.info "STATE_CHANGE|#{@state}|#{new_state}"
      #        @state = new_state
      #      end

      def start
        super

        create_receiver
        @receiver.start

        #        @logger.info('Listening for tasks')
        #        self.state = :running
        #        loop do
        #          timers.wait
        #          if @state == :stopped
        #            @con.stop
        #            return
        #          end
        #        end
        #        @con.stop
      end

#      def stop
#        self.state = :stopped
#      end


      private


      def configure_self(options)
        super

        @keeper_type = options.fetch(:keeper_type, 'generic')
        @name_prefix = options.fetch(:name_prefix, "tef.#{tef_env}")
        @in_queue = options.fetch(:in_queue, "#{@name_prefix}.keeper.#{@keeper_type}")
        @output_exchange = options.fetch(:output_exchange, "#{@name_prefix}.#{@keeper_type}.keeper_generated_messages")
        @receiver = options.fetch(:receiver_class, TEF::Keeper::Receiver)
      end

      def create_receiver
        @logger.debug('creating receiver')

        @options = {
            in_queue: @in_queue,
            out_queue: @output_exchange,
            logger: @logger,
            callback: @task_callback
        }

        @receiver = @receiver.new(@options)
      end

    end
  end
end
