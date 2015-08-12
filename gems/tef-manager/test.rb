# todo - remove this old file

require_relative 'lib/tef/manager/models/task'

def tef_env
  !ENV['TEF_ENV'].nil? ? ENV['TEF_ENV'].downcase : 'dev'
end

def tef_config
  !ENV['TEF_CONFIG'].nil? ? ENV['TEF_CONFIG'] : "#{File.dirname(__FILE__)}/config"
end

ActiveRecord::Base.time_zone_aware_attributes = true
ActiveRecord::Base.default_timezone = :local

db_config_file = "#{tef_config}/database_#{tef_env}.yml"
db_config = YAML.load(File.open(db_config_file))

ActiveRecord::Base.establish_connection(db_config)
ActiveRecord::Base.table_name_prefix = "tef_#{tef_env}_"
ActiveRecord::Base.logger =  Logger.new(STDOUT)



task = TEF::Task.new
task.guid = 'test'
task.dispatched = nil
task.save
