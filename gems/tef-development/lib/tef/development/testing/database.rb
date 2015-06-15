require 'active_record'


module TEF
  module Development
    module Testing

      def self.connect_to_test_db(db_config_file = nil)
        ActiveRecord::Base.time_zone_aware_attributes = true
        ActiveRecord::Base.default_timezone = :local

        unless db_config_file
          raise 'Environmental variable TEF_DB_CONFIG_PATH must be set or a configuration file provided' if ENV['TEF_DB_CONFIG_PATH'].nil?

          db_config_file = ENV['TEF_DB_CONFIG_PATH']
        end

        db_config = YAML.load_file(db_config_file)

        ActiveRecord::Base.establish_connection(db_config)
        ActiveRecord::Base.logger = Logger.new(File.open('tef_test_database.log', 'a'))
      end

    end
  end
end
