require 'workers'
require 'json'
require 'socket'
require 'process'

module TEF
  module Worker
    class BaseWorker < Core::InnerComponent

      attr_reader :worker_type, :status_interval
      attr_accessor :status, :name, :root_location


      def initialize(options)
        super


        set_message_action(worker_callback)


        @status = :idle

        @logger.info("Worker(#{@worker_type}) created.")
        @logger.debug("Input queue: #{@in_queue.name}")
        @logger.debug("Output exchange: #{@output_exchange.name}")
        @logger.debug("Manager queue: #{@output_exchange.name}")
        @logger.debug("Root location: #{@root_location}")
      end

      def start
        super

        update_manager
        set_heartbeat
      end

      def stop
        @heartbeat_timer.cancel if @heartbeat_timer
      end

      def work(task)
        # todo - this method logic still needs more testing

        @logger.info "Task received: #{task[:guid]}"
        @logger.info "Task payload: #{task}"

        ## recovering from a bad task is important...don't crash because of one
        ##begin

        # todo - how to handle a bad task?
        unless task.has_key?(:task_data)
          # Need to make sure that it is a Hash for proper error handling and data storage
          task[:task_data] = {}
          raise(ArgumentError, ':task must include a :task_data key')
        end

        unless task[:task_data].is_a?(Hash)
          received_type = task[:task_data].class

          # Need to make sure that it is a Hash for proper error handling and data storage
          task[:task_data] = {}
          raise(ArgumentError, ":task_data must be a Hash of task data. Was #{received_type}")
        end
        # raise(ArgumentError, ':task_data must include a :working_directory key') unless task[:task_data].has_key? :working_directory

        # todo - need some more testing here
        # task specific root should override general root
        root_location = task[:task_data][:root_location] || @root_location
        raise(ArgumentError, 'Root location cannot be determined. A root location must be provided in the task or configured via environmental variable') unless root_location

        if task[:task_data][:working_directory]
          task[:task_data][:working_directory] = "#{root_location}/#{task[:task_data][:working_directory]}"
        else
          task[:task_data][:working_directory] = root_location
        end

        output = @runner.work(task)
        #@logger.info 'Finished working.'

        #@logger.info "output: #{output.inspect}"
        #puts output

        ##rescue => e
        ##  puts e.message
        ##  puts e.backtrace
        ##end

        output
      end

      def update_manager(status = @status)
        @status = status
        @logger.debug("Update manager with #{@status}")

        # todo - need tests/documentation around status update format
        status_data = {
            type: 'worker_status',
            worker_type: "#{worker_type}",
            # todo - Workers should probably have name, huh?
            name: "#{@name}",
            status: "#{@status}",
            exchange_name: "#{@in_queue.name}"
        }

        @manager_queue.publish(JSON.generate(status_data))
      end


      private


      def validate_configuration_options(options)
        super

        raise(ArgumentError, 'Configuration options must have an :output_exchange') unless options[:output_exchange]
        raise(ArgumentError, 'Configuration options must have a :manager_queue') unless options[:manager_queue]
        raise(ArgumentError, ":status_interval can only be an integer. Got #{options[:status_interval].class}") unless (options[:status_interval].is_a?(Integer) || options[:status_interval].nil?)
      end

      def configure_self(options)
        super

        @root_location = options[:root_location]
        @status_interval = options.fetch(:status_interval, 20)
        @manager_queue = options[:manager_queue]
        @worker_type = options.fetch(:worker_type, 'generic')
        @runner = options.fetch(:runner, TaskRunner::Runner.new(logger: @logger))
        @name = options.fetch(:name, "#{Socket.gethostname}.#{Process.pid}")
      end

      def worker_callback
        lambda { |_delivery_info, _properties, payload|
          @logger.debug 'Message received'

          # todo - more functionality that needs testing
          begin
            task = JSON.parse(payload, symbolize_names: true)
          rescue
            @logger.error("INVALID_TASK_JSON|#{payload}")
            task = nil
          end

          unless task.nil?
            #@worker_queue.channel.acknowledge(delivery_info.delivery_tag, false)


            update_manager :working

            begin
              @logger.debug 'starting work'
              work_output = work(task)
              task[:task_data][:results] ||= []
              task[:task_data][:results] = work_output

            rescue Exception => ex
              task[:task_data][:results] ||= []
              task[:task_data][:results] = "ERROR: #{ex.message}"
              @logger.error "Error raised in #work: #{ex.class} - #{ex.message}"
            end

            begin
              @output_exchange.publish(JSON.generate(task), routing_key: 'task')
              update_manager :task_complete
            rescue Exception => ex
              @logger.error "Error publishing result #{ex.message}"
            end
          end

          @logger.debug 'Finished processing message'
          update_manager :idle
        }
      end

      def set_heartbeat
        @heartbeat_timer = Workers::PeriodicTimer.new(@status_interval) do
          # Multiple threads using the same channel goes against bunny's concurrency safety for publishing, so we
          # need to make a new channel (and, by extension, queue) object for the heartbeat to use. Note that it is
          # important to declare the new queue object with the same special options as the original queue.

          # todo - no testing around this right now
          unless @new_queue_created
            @manager_queue = @manager_queue.channel.connection.create_channel.queue(@manager_queue.name, @manager_queue.options)
            @new_queue_created = true
          end


          # todo - probably need to add some auto-stopping in case the worker gets killed without #stop-ing
          update_manager
        end
      end

    end
  end
end
