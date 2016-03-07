require 'json'
require 'bunny'

module TEF
  module Keeper
    # Simple class to receive tasks from workers, call a callback and then requeue if needed
    # todo - have this class use the InnerComponent class
    class Receiver < Bunny::Consumer

      attr_reader :logger


      def initialize(options)
        raise(ArgumentError, 'Configuration options must have an :in_queue') unless options[:in_queue]
        raise(ArgumentError, 'Configuration options must have a :callback') unless options[:callback]

        @logger = options.fetch(:logger, Logger.new($stdout))
        @in_queue = options[:in_queue]
        @task_queue = options[:out_queue]
        @task_callback = options[:callback]

        # todo - test the ack flag being used
        super(@in_queue.channel, @in_queue, @in_queue.channel.generate_consumer_tag, false)
        #@logger.debug("Receiver created, receiving from #{@in_queue.name} and sending to #{@task_queue.name}")
      end

      def start
        set_message_action
        listen_for_messages
      end

      def stop
        # todo - What is this supposed to do?
      end


      private


      def set_message_action
        on_delivery do |delivery_info, _properties, message_body|

          begin
            task = JSON.parse(message_body, symbolize_names: true)
            @logger.info("Received #{task[:task_type]} task #{task[:guid]}")

            @task_callback.call(delivery_info, _properties, task, @logger)

            forward_task(task)
          rescue JSON::ParserError
            @logger.error("JSON problem with: #{message_body}")
          rescue => e
            @logger.error("Callback error #{e.class}: #{e}")
            @logger.debug("backtrace: #{e.backtrace}")
          end

          @in_queue.channel.acknowledge(delivery_info.delivery_tag, false)
        end

        #@logger.debug('Message action set')
      end

      def listen_for_messages
        @logger.info('Listening for results...')

        # Non-blocking is the default but passing it in anyway for clarity
        @in_queue.subscribe_with(self, block: false)
      end

      def forward_task(task)
        # todo - still need a requirement to make the tasks persistent
        #@task_queue.publish(JSON.generate(task), :persistent => true)
        @task_queue.publish(JSON.generate(task), routing_key: 'task') if @task_queue
      end

    end
  end
end
