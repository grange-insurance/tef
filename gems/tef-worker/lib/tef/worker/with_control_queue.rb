# todo - get rid of this file

#module TEF
#  module WithControlQueue
#    def init_control(control_queue)
#      @control_queue = control_queue
#      @control_queue.subscribe(block: false, ack: true) do |delivery_info, properties, payload|
#        handle_control_message delivery_info, properties, payload
#        @control_queue.channel.acknowledge(delivery_info.delivery_tag, false)
#      end
#    end
#
#    def handle_control_message(_delivery_info, properties, msg_json)
#      begin
#        message = JSON.parse(msg_json, symbolize_names: true)
#      rescue => ex
#        err = "CONTROL_FAILED|PARSE_JSON|#{ex.message}|#{msg_json}"
#        @logger.error err
#        reply_if_requested @control_queue, properties, err
#        return
#      end
#
#      msg_type = message.fetch(:type, nil)
#
#      if msg_type.nil?
#        err = "CONTROL_FAILED|INVALID_JSON|NO_TYPE|#{msg_json}"
#        @logger.error err
#        reply_if_requested @control_queue, properties, err
#        return
#      end
#
#      @logger.info "CONTROL_RECEIVED|#{msg_type}"
#
#      begin
#        response = send("control_#{msg_type}", message)
#      rescue => ex
#        response = "CONTROL_FAILED|CALL_FAILED|#{msg_type}|#{ex.message}|#{msg_json}"
#        @logger.error response
#      end
#
#      reply_if_requested @control_queue, properties, response
#    end
#
#    def reply_if_requested(queue, properties, payload)
#      return if properties.reply_to.nil?       || properties.reply_to.length == 0
#      return if properties.correlation_id.nil? || properties.correlation_id.length == 0
#
#      exchange = queue.channel.default_exchange
#
#      if payload.is_a?(Hash)
#        response = JSON.generate(payload)
#      else
#        response = JSON.generate(response: payload)
#      end
#      exchange.publish(response, routing_key: properties.reply_to, correlation_id: properties.correlation_id)
#    end
#  end
#end
