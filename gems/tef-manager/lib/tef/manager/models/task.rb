require 'active_record'
require 'json'
require 'yaml'

# todo - test this class more
module TEF
  module Manager
    # Database representation of a Task.
    class Task < ActiveRecord::Base

      has_many :task_resources, autosave: true

      def load_hash(json_hash)
        self.task_type    = json_hash[:task_type]
        self.guid         = json_hash[:guid]
        self.priority     = json_hash[:priority] || 1
        self.task_data    = YAML.dump(json_hash[:task_data])
        self.suite_guid   = json_hash.fetch(:suite_guid, nil)
        self.time_limit   = json_hash.fetch(:time_limit, nil)
        res_str = json_hash[:resources] || ''

        resources = res_str.split('|')

        resources.each do |res|
          task_res = TaskResource.new
          task_res.resource_name = res
          task_resources.push task_res
        end
      end

      def resource_names
        task_resources.map(&:resource_name)
      end

      def to_h
        {type: 'task',
         task_type: task_type,
         guid: guid,
         priority: priority,
         task_data: load_data(task_data),
         suite_guid: suite_guid,
         time_limit: time_limit,
         resources: task_resources.map(&:resource_name).join('|')
        }
      end

      def to_json
        JSON.generate to_h
      end

      def load_data data
        begin
          if yaml_string?(data)
            return YAML.load(data)
          elsif data.class.to_s == 'String'
            return eval(data)
          end
        rescue => e
          @logger.warn("Unable to load data, Error: #{e},#{data}")
        end
      end

      def yaml_string?(string)
        !!string[/^---/m]
      end

    end
  end
end
