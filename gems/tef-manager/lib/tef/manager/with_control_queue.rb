module TEF
  # this module provides common functionality for object that need a control queue.
  module WithControlQueue
    def init_control(control_queue)
      @control_queue = control_queue

      # todo - still need to redo the subscription mechanism to properly block/ack
      # @control_queue.subscribe(block: false, ack: true) do |delivery_info, properties, payload|
      self.on_delivery do |delivery_info, properties, payload|
        handle_control_message(delivery_info, properties, payload)
        @control_queue.channel.acknowledge(delivery_info.delivery_tag, false)
      end

      # Non-blocking is the default but passing it in anyway for clarity
      @control_queue.subscribe_with(self, block: false)
    end

    def handle_control_message(_delivery_info, properties, message_payload)
      begin
        message = JSON.parse(message_payload, symbolize_names: true)
      rescue JSON::ParserError => exception
        error = "CONTROL_FAILED|PARSE_JSON|#{exception.message}|#{message_payload}"
        @logger.error error

        reply_if_requested(@control_queue, properties, error)
        return
      end

      message_type = message.fetch(:type, nil)

      if message_type.nil?
        error = "CONTROL_FAILED|INVALID_JSON|NO_TYPE|#{message_payload}"
        @logger.error error

        reply_if_requested(@control_queue, properties, error)
        return
      end

      @logger.debug "CONTROL_RECEIVED|#{message_type}"

      begin
        response = send("control_#{message_type}", message)
      rescue => exception
        response = "CONTROL_FAILED|CALL_FAILED|#{message_type}|#{exception.message}|#{exception.backtrace}|#{message_payload}"
        @logger.error response
      end

      reply_if_requested(@control_queue, properties, response)
    end

    def reply_if_requested(queue, properties, payload)
      return unless properties.reply_to
      return unless properties.correlation_id

      exchange = queue.channel.default_exchange

      if payload.is_a?(Hash)
        response = JSON.generate(payload)
      else
        response = JSON.generate(response: payload)
      end

      exchange.publish(response, routing_key: properties.reply_to, correlation_id: properties.correlation_id)
    end

    private :handle_control_message, :init_control

  end
end
