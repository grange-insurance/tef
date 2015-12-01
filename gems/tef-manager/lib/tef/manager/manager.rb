module TEF
  module Manager
    # The task queue supplies tasks to the dispatcher.
    class Manager < Bunny::Consumer

      include TEF::WithControlQueue


      attr_reader :logger, :input_queue, :state, :dispatcher, :task_queue, :worker_collective, :dispatch_interval


      def initialize(options)
        validate_configuration_options(options)
        configure_self(options)

        # todo - test the ack flag being used
        super(@input_queue.channel, @input_queue, @input_queue.channel.generate_consumer_tag, false)

        set_state(:starting)
      end

      def start
        set_message_action
        listen_for_messages

        set_state(:running)

        set_dispatch_loop
      end

      def stop
        set_state(:stopped)

        @dispatch_timer.cancel if @dispatch_timer
      end

      def set_state(new_state)
        #todo - maybe some better logging when state is nil (such as when it is set for the first time)
        @logger.info "STATE_CHANGE|#{@state}|#{new_state}"
        @state = new_state
      end


      private


      def validate_configuration_options(options)
        raise(ArgumentError, 'An :input_queue must be provided.') unless options[:input_queue]
        raise(ArgumentError, 'A :dispatcher must be provided.') unless options[:dispatcher]
        raise(ArgumentError, 'A :task_queue must be provided.') unless options[:task_queue]
        raise(ArgumentError, 'A :worker_collective must be provided.') unless options[:worker_collective]
        raise(ArgumentError, ":dispatch_interval can only be an integer. Got #{options[:dispatch_interval].class}") unless options[:dispatch_interval].is_a?(Integer) || !options.has_key?(:dispatch_interval)
      end

      def configure_self(options)
        @logger = options.fetch(:logger, Logger.new($stdout))
        @rabbit_connection = options[:rabbit_connection]
        @dispatch_interval = options.fetch(:dispatch_interval, 10)
        @input_queue = options[:input_queue]
        @dispatcher = options[:dispatcher]
        @task_queue = options[:task_queue]
        @worker_collective = options[:worker_collective]
      end

      def set_message_action
        on_delivery do |delivery_info, properties, message_body|

          begin
            message = JSON.parse(message_body, symbolize_names: true)

            case message[:type]
              when 'dispatch_tasks'
                handle_dispatch_tasks_message(delivery_info, properties, message)
              when 'set_state'
                handle_set_state_message(delivery_info, properties, message)
              when 'pause_suite'
                handle_pause_suite_message(delivery_info, properties, message)
              when 'ready_suite'
                handle_ready_suite_message(delivery_info, properties, message)
              when 'stop_suite'
                handle_stop_suite_message(delivery_info, properties, message)
              when 'task'
                handle_task_message(delivery_info, properties, message)
              when 'get_workers'
                worker_data = handle_get_workers_message(delivery_info, properties, message)
                reply_if_requested(@input_queue, properties, worker_data)
              when 'worker_status'
                handle_worker_status_message(delivery_info, properties, message)
              else
                # todo - figure out what to do in this case
                raise "boom!: don't know what a '#{message[:type]}' message is"
              #     logger.warn "Do not know how to handle a #{payload[:type]} message"
            end
          rescue JSON::ParserError => exception
            error = "MESSAGE_ERROR|INVALID_JSON|#{exception.message}|#{message_body}"
            @logger.error error

            reply_if_requested(@input_queue, properties, error)
          end


          @input_queue.channel.acknowledge(delivery_info.delivery_tag, false)
        end
      end

      def listen_for_messages
        #todo - find a way to test for blocking flag/behavior
        # Non-blocking is the default but passing it in anyway for clarity
        @input_queue.subscribe_with(self, block: false)
      end

      def handle_dispatch_tasks_message(delivery_info, properties, payload)
        unless @state == :running
          @logger.info "Not dispatching tasks while state == #{@state}"
          return
        end

        @dispatcher.dispatch_tasks
      end

      def handle_set_state_message(delivery_info, properties, payload)
        valid_states = [:running, :paused, :stopped]

        data = payload[:data]

        raise(ArgumentError, 'INVALID_JSON|NO_DATA') unless data

        data = data.to_sym

        raise(ArgumentError, "INVALID_JSON|INVALID_STATE|#{data}") unless valid_states.include?(data)

        set_state(data)
      end

      def handle_pause_suite_message(delivery_info, properties, message)
        raise(ArgumentError, 'INVALID_JSON|NO_DATA') unless message[:data]

        @dispatcher.pause_suite(message[:data])
      end

      def handle_ready_suite_message(delivery_info, properties, message)
        raise(ArgumentError, 'INVALID_JSON|NO_DATA') unless message[:data]

        @dispatcher.ready_suite(message[:data])
      end

      def handle_stop_suite_message(delivery_info, properties, message)
        raise(ArgumentError, 'INVALID_JSON|NO_DATA') unless message[:data]

        @dispatcher.stop_suite(message[:data])
      end

      def handle_task_message(delivery_info, properties, message)
        @task_queue.push message
      end

      def handle_get_workers_message(delivery_info, properties, message)
        @worker_collective.get_workers
      end

      def handle_worker_status_message(delivery_info, properties, message)
        unless @worker_collective.workers[message[:name]]
          if message[:exchange_name] && message[:status]
            worker_queue = @input_queue.channel.queue(message[:exchange_name], durable: true)

            @worker_collective.register_worker(message[:name], worker_queue, message)
          end
        end

        @worker_collective.set_worker_status(message)
      end

      def set_dispatch_loop
        @dispatch_timer = Workers::PeriodicTimer.new(dispatch_interval) do
          # todo - probably need to add some auto-stopping in case the dispatcher gets killed without #stop-ing

          # May have to give this thread its own channel to publish through if we run into frame errors
          @input_queue.publish(JSON.generate({type: 'dispatch_tasks'}))
        end
      end

    end

  end

end
