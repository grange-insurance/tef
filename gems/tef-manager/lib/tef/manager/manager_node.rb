require 'etcd'
require 'res_man'
require 'tef/core'
require 'active_record'


module TEF
  module Manager
    # High level object that ties all the components together into a functional app
    class ManagerNode < Core::OuterComponent


      # todo - make the OuterComponent loosely configured?
      def initialize(options = {})
        super
      end


      def start
        super

        init_database
        assemble_dispatcher
        assemble_manager

        @manager.start
      end

      def stop
        # The dispatcher might not have been created and thus still be a Class instead
        # of an instance thereof
        @manager.stop if @manager.respond_to?(:stop)

        ActiveRecord::Base.remove_connection

        super
      end


      private


      def configure_self(options)
        super

        #todo - test this
        @db_logger = options.fetch(:db_logger, nil)

        @name_prefix = options.fetch(:name_prefix, "tef.#{tef_env}")
        @logger.progname = 'tef_manager'


        @in_queue = options.fetch(:in_queue, "#{@name_prefix}.manager")

        @manager = options.fetch(:manager_class, TEF::Manager::Manager)
        @task_queue = options.fetch(:task_queue_class, TEF::Manager::TaskQueue)
        @dispatcher = options.fetch(:dispatcher_class, TEF::Manager::Dispatcher)
        @worker_collective = options.fetch(:worker_collective_class, TEF::Manager::WorkerCollective)
        @worker_update_interval = options.fetch(:worker_update_interval, 30)

        @resource_manager = options.fetch(:resource_manager_class, ResMan::Manager)

        # todo - These two don't seem to do anything but I'll leave them on for now
        @resource_store_server = options.fetch(:resource_store_server, 'localhost')
        @resource_store_port = options.fetch(:resource_store_port, 4001)

        #todo - this will get moved to and tested in the resource manager
        @base_store_key = options.fetch(:base_store_key, default_base_store_key)
        @resource_store = options.fetch(:resource_store, default_resource_store)

      end

      def create_task_queue
        @logger.info('Creating task queue')
        @task_queue = @task_queue.new(logger: @logger, input_queue: @task_queues_queue)
      end

      def create_worker_collective
        collective_options = {
            logger: @logger,
            control_queue: @worker_queue,
            worker_update_interval: @worker_update_interval,
            resource_manager: @resource_manager
        }
        @logger.info("Creating worker collective... Worker update interval: #{collective_options[:worker_update_interval]}")
        @worker_collective = @worker_collective.new(collective_options)
      end

      #todo - just pass in a resource manager directly (or create one) and let it worry about its stores
      def create_resource_manager
        @logger.info('Creating resource manager')
        #todo - give this a real client id instead of a fake one
        @resource_manager = @resource_manager.new(@base_store_key, @resource_store, '123456')
      end

      def assemble_manager
        manager_options = {
            logger: @logger,
            input_queue: @in_queue,
            task_queue: @task_queue,
            worker_collective: @worker_collective,
            dispatcher: @dispatcher
        }

        @logger.info('Creating manager')
        @manager = @manager.new(manager_options)
      end

      def assemble_dispatcher
        create_task_queue
        create_resource_manager
        create_worker_collective

        dispatcher_options = {
            logger: @logger,
            task_queue: @task_queue,
            resource_manager: @resource_manager,
            worker_collective: @worker_collective,
            control_queue: @dispatcher_queue
        }

        @logger.info('Creating dispatcher')
        @dispatcher = @dispatcher.new(dispatcher_options)
      end

      def init_database
        #todo - maybe some testing around all of these options
        ActiveRecord::Base.time_zone_aware_attributes = true
        ActiveRecord::Base.default_timezone = :local

        db_config_file = "#{tef_config}/database_#{tef_env}.yml"
        @logger.info "Connecting to dabatase using info from #{db_config_file}"
        db_config = YAML.load(File.open(db_config_file))

        ActiveRecord::Base.establish_connection(db_config)
        ActiveRecord::Base.table_name_prefix = "tef_#{tef_env}_"

        @logger.info "Table name prefix is: #{ActiveRecord::Base.table_name_prefix}"
        ActiveRecord::Base.logger = @db_logger
      end

      #todo - this will get moved to and tested in the resource manager
      def etcd_env_host
        "TEF_ETCD_HOST_#{tef_env.upcase}"
      end

      #todo - this will get moved to and tested in the resource manager
      def etcd_env_port
        "TEF_ETCD_PORT_#{tef_env.upcase}"
      end

      def tef_config
        !ENV['TEF_MANAGER_DB_CONFIG'].nil? ? ENV['TEF_MANAGER_DB_CONFIG'] : "#{File.dirname(__FILE__)}/../../../config"
      end

      #todo - this will get moved to and tested in the resource manager
      def default_base_store_key
        "/tef/#{tef_env}"
      end

      #todo - this will get moved to and tested in the resource manager
      def default_resource_store
        host = ENV.fetch(etcd_env_host, '127.0.0.1')
        port = ENV.fetch(etcd_env_port, 4001)
        @logger.info "Connecting to EtcD at #{host}:#{port}"
        client = Etcd.client(host: host, port: port)
        @logger.info "Connected... Resource base key is: '#{@base_store_key}'"
        client
      end

    end
  end
end
