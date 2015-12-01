module TEF

  # todo - Rename this module. There are no longer different types of queue.
  module WithControlQueue

    def handle_control_message(queue, _delivery_info, properties, message_payload)
      begin
        message = JSON.parse(message_payload, symbolize_names: true)
      rescue JSON::ParserError => exception
        error = "CONTROL_FAILED|PARSE_JSON|#{exception.message}|#{message_payload}"
        @logger.error error

        reply_if_requested(queue, properties, error)
        return
      end

      message_type = message.fetch(:type, nil)

      if message_type.nil?
        error = "CONTROL_FAILED|INVALID_JSON|NO_TYPE|#{message_payload}"
        @logger.error error

        reply_if_requested(queue, properties, error)
        return
      end

      @logger.debug "CONTROL_RECEIVED|#{message_type}"

      begin
        response = send("control_#{message_type}", message)
      rescue => exception
        response = "CONTROL_FAILED|CALL_FAILED|#{message_type}|#{exception.message}|#{exception.backtrace}|#{message_payload}"
        @logger.error response
      end

      reply_if_requested(queue, properties, response)
    end

    def reply_if_requested(queue, properties, payload)
      return unless properties.reply_to
      return unless properties.correlation_id

      exchange = queue.channel.default_exchange

      # todo - why the difference?
      if payload.is_a?(Hash)
        response = JSON.generate(payload)
      else
        response = JSON.generate(response: payload)
      end

      exchange.publish(response, routing_key: properties.reply_to, correlation_id: properties.correlation_id)
    end

    private :handle_control_message

  end
end
