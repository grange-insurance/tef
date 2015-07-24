require 'active_record'


module TEF
  module Development
    module Testing

      def self.connect_to_test_db(options = {})
        ActiveRecord::Base.time_zone_aware_attributes = true
        ActiveRecord::Base.default_timezone = :local

        db_config = options[:db_config]
        db_config_file = options[:db_config_file]

        unless db_config
          unless db_config_file
            raise 'Environmental variable TEF_DB_CONFIG_PATH must be set or a configuration file provided' if ENV['TEF_DB_CONFIG_PATH'].nil?

            db_config_file = ENV['TEF_DB_CONFIG_PATH']
          end

          db_config = YAML.load_file(db_config_file)
        end

        ActiveRecord::Base.establish_connection(db_config)
        ActiveRecord::Base.logger = Logger.new(File.open('tef_test_database.log', 'a'))
      end

    end
  end
end
