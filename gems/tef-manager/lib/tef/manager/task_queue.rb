require 'logger'
require 'json'


module TEF
  module Manager
    # The task queue supplies tasks to the dispatcher.
    class TaskQueue < Bunny::Consumer
      attr_reader :logger, :input_queue

      def initialize(options)
        raise(ArgumentError, 'An :input_queue must be provided.') unless options[:input_queue]
        @logger = options.fetch(:logger, Logger.new($stdout))
        @input_queue = options[:input_queue]

        #todo - check other consumer initializers for needed args and find a way to test for them
        channel = @input_queue.channel
        # todo - test the ack flag being used
        super(channel, @input_queue, channel.generate_consumer_tag, false)

        set_message_action
        listen_for_messages
      end

      def push(task_hash)
        task = Task.new
        task.load_hash(task_hash)
        task.status = 'ready'

        # Caller will catch save exceptions
        task.save

        # Assume success if it didn't explode
        true
      end

      def pop(unavailable_resources, worker_types)
        unavailable_resources ||= []
        worker_types ||= []
        task = nil

        begin
          ActiveRecord::Base.connection_pool.with_connection do

            type_query = 'task_type IN (:worker_types)'
            resource_query = "id NOT IN (SELECT task_id FROM #{TaskResource.table_name} WHERE resource_name IN(:unavailable_resources))"
            paused_exclusion_query = "((status <> 'paused') OR (status is null))"
            ready_only_query = "(status= 'ready')"

            needed_queries = ['dispatched IS NULL']
            needed_queries << ready_only_query
            needed_queries << paused_exclusion_query
            needed_queries << type_query unless worker_types.empty?
            needed_queries << resource_query unless unavailable_resources.empty?

            tasks = Task.where(needed_queries.join(' AND '), {worker_types: worker_types, unavailable_resources: unavailable_resources}).order(priority: :desc)
            task = tasks.first
          end
        rescue => exception
          # TODO: Handle DB errors gracefully
          error = "POP_FAILED|#{exception.message}|#{exception.backtrace}"
          @logger.error error
        end

        task
      end

      def set_message_action
        self.on_delivery do |delivery_info, properties, payload|
          handle_input_message delivery_info, properties, payload
          @input_queue.channel.acknowledge(delivery_info.delivery_tag, false)
        end
      end

      def listen_for_messages
        #todo - find a way to test for blocking flag/behavior
        # note - false is currently the default option but it doesn't hurt to make sure
        @input_queue.subscribe_with(self, block: false)
        @logger.debug('TaskQueue connected to RabbitMQ')
      end

      #todo - this is all basically the WithControlQueue module but with different logging. Refactor.

      def handle_input_message(_delivery_info, properties, payload)
        logger.info "handling message: #{payload}"

        begin
          message = JSON.parse(payload, symbolize_names: true)

        rescue JSON::ParserError => exception
          error = "INPUT_FAILED|PARSE_JSON|#{exception.message}|#{payload}"
          @logger.error error
          reply_if_requested @input_queue, properties, error
          return
        end

        message_type = message.fetch(:type, nil)

        if message_type.nil?
          error = "INPUT_FAILED|INVALID_JSON|NO_TYPE|#{payload}"
          @logger.error error
          reply_if_requested @input_queue, properties, error
          return
        end

        begin
          response = send("handle_#{message_type}_input", message)
        rescue => exception
          error = "INPUT_FAILED|CALL_FAILED|#{message_type}|#{exception.message}|#{payload}"
          @logger.error error
          reply_if_requested @input_queue, properties, error
          return
        end

        reply = {response: response}

        reply_if_requested @input_queue, properties, reply
      end

      def handle_task_input(message)
        push message
      end

      def reply_if_requested(queue, properties, payload)
        return unless properties.reply_to

        reply_exchange = queue.channel.default_exchange

        if payload.is_a?(Hash)
          response = JSON.generate(payload)
        else
          response = JSON.generate(response: payload)
        end

        reply_exchange.publish(response, routing_key: properties.reply_to, correlation_id: properties.correlation_id)
      end

      private :set_message_action, :listen_for_messages, :handle_input_message, :reply_if_requested
    end
  end
end
