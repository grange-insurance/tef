require 'tef/core'

module TEF
  module Keeper
    class Keeper < TefComponent

      EXIT_CODE_FAILED_QUEUE = 3

      attr_reader :out_queue_name, :in_queue_name, :keeper_type


      def initialize(options)
        super

        @keeper_type = options.fetch(:keeper_type, 'generic')
#        @state             = :waking
        @queue_prefix = options.fetch(:queue_prefix, "tef.#{tef_env}")
        @out_queue = options[:out_queue]
        @in_queue = options.fetch(:in_queue, "#{@queue_prefix}.keeper.#{@keeper_type}")
        @receiver = options.fetch(:receiver_class, TEF::Keeper::Receiver)

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

        create_message_queues
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


      def create_message_queues
        @logger.debug('Creating message queues')

        channel = @connection.create_channel

        begin
          if @out_queue
            @out_queue = channel.queue(@out_queue, :durable => true) if @out_queue.is_a?(String)
            @out_queue_name = @out_queue.name
            @logger.info "Out queue: #{@out_queue_name} (channel #{channel.id})"
          end

          @in_queue = channel.queue(@in_queue, :durable => true) if @in_queue.is_a?(String)
          @in_queue_name = @in_queue.name
          @logger.info "In queue: #{@in_queue_name} (channel #{channel.id})"
        rescue => ex
          @logger.error("Failed to create control queues.  #{ex.message}")
          exit(EXIT_CODE_FAILED_QUEUE)
        end
      end

      def create_receiver
        @logger.debug('creating receiver')

        @options = {
            in_queue: @in_queue,
            out_queue: @out_queue,
            logger: @logger,
            callback: @task_callback
        }

        @receiver = @receiver.new(@options)
      end


      # Don't see this being used right now
      #      def tef_config
      #        !ENV['TEF_CONFIG'].nil? ? ENV['TEF_CONFIG'] : "#{File.dirname(__FILE__)}/../config"
      #      end


    end
  end
end
