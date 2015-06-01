require 'spec_helper'
require 'active_record'
require 'database_cleaner'

# todo - a lot of these are integration tests and should be moved accordingly
describe 'Task, Unit' do

  clazz = TEF::Manager::Task

  describe 'instance level' do
    before(:all) do
      ActiveRecord::Base.time_zone_aware_attributes = true
      ActiveRecord::Base.default_timezone = :local

      db_config = YAML.load(File.open("#{tef_config}/database_#{tef_env}.yml"))
      ActiveRecord::Base.establish_connection(db_config)
      ActiveRecord::Base.table_name_prefix = "tef_#{tef_env}_"
      ActiveRecord::Base.logger = Logger.new(File.open('database.log', 'a'))

      DatabaseCleaner.strategy = :truncation, {only: %w(tef_dev_tasks tef_dev_task_resources)}
      DatabaseCleaner.start
    end

    before(:each) do
      @task_hash = {
          type: 'task',
          task_type: 'type_1',
          guid: SecureRandom.uuid,
          priority: 5,
          resources: 'res_1|res_2|res_3',
          task_data: 'data',
          time_limit: 1
      }

      @task = clazz.new
    end

    after(:each) do
      DatabaseCleaner.clean
    end

    it 'can be populated from a hash' do
      expect(@task).to respond_to(:load_hash)

      @task.load_hash(@task_hash)
      @task.save!

      expect(@task.task_type).to eq(@task_hash[:task_type])
      expect(@task.priority).to eq(@task_hash[:priority])
      expect(@task.task_resources.count).to eq(3)
      expect(@task.task_data).to eq(YAML.dump(@task_hash[:task_data]))
    end

    it 'defaults to the lowest priority if none is given' do
      @task_hash.delete(:priority)

      @task.load_hash(@task_hash)
      @task.save!

      expect(@task.priority).to eq(1)
    end

    it 'can convert itself back to a hash' do
      expect(@task).to respond_to(:to_h)

      @task.load_hash(@task_hash)
      @task.save!

      new_hash = @task.to_h

      expect(new_hash[:task_type]).to eq(@task_hash[:task_type])
      expect(new_hash[:priority]).to eq(@task_hash[:priority])
      expect(new_hash[:task_data]).to eq(@task_hash[:task_data])
    end

    it 'can convert itself back to json' do
      @task.load_hash(@task_hash)
      @task.save!

      json_data = @task.to_json

      new_hash = JSON.parse(json_data, symbolize_names: true)

      expect(new_hash[:task_type]).to eq(@task_hash[:task_type])
      expect(new_hash[:priority]).to eq(@task_hash[:priority])
      expect(new_hash[:task_data]).to eq(@task_hash[:task_data])
    end

    it 'knows the resources used by a task' do
      expect(@task).to respond_to(:resource_names)

      @task.load_hash(@task_hash)

      expect(@task.resource_names).to eq(['res_1', 'res_2', 'res_3'])
    end

  end

end
