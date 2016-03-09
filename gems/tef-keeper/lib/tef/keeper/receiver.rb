require 'json'
require 'bunny'

module TEF
  module Keeper
    # Simple class to receive tasks from workers, call a callback and then requeue if needed
    class Receiver < TEF::Core::InnerComponent


      def initialize(options)
        super

        #@logger.debug("Receiver created, receiving from #{@in_queue.name} and sending to #{@task_queue.name}")
      end

      def start
        set_message_action(message_callback)

        super
      end

      def stop
        # todo - What is this supposed to do?
      end


      private


      def validate_configuration_options(options)
        super

        raise(ArgumentError, 'Configuration options must have a :callback') unless options[:callback]
      end

      def configure_self(options)
        super

        @task_queue = options[:out_queue]
        @task_callback = options[:callback]
      end

      def message_callback
        lambda { |delivery_info, _properties, message_body|

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
        }

        #@logger.debug('Message action set')
      end

      def listen_for_messages
        @logger.info('Listening for results...')

        super
      end

      def forward_task(task)
        # todo - still need a requirement to make the tasks persistent
        #@task_queue.publish(JSON.generate(task), :persistent => true)
        @task_queue.publish(JSON.generate(task), routing_key: 'task') if @task_queue
      end

    end
  end
end
