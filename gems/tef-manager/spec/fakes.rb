module TEF
  module Development
    module Testing
      module Fakes

        def create_fake_task
          FakeTask.new
        end

        def create_fake_worker_collective(workers = [])
          FakeWorkerCollective.new(workers)
        end

      end
    end
  end
end

module TEF
  module Development
    module Testing
      module Fakes

        # A fake task that does not rely on the database
        class FakeTask
          attr_accessor :task_type, :guid, :priority, :resources, :task_data, :suite_guid, :dispatched, :time_limit, :save_called, :destroy_called, :status

          def initialize
            @task_type = 'echo'
            @guid = SecureRandom.uuid
            @suite_guid = SecureRandom.uuid
            @priority = 5
            @resources = 'pipe|delminated|list'
            @task_data = 'ew0KICAibWVzc2FnZSI6ICJIZWxsbyBXb3JsZCINCn0='
            @task_resources = []
            @dispatched = nil
            @time_limit = nil
            @save_called = 0
            @destroy_called = 0
            @status = nil
          end

          def save
            @save_called += 1
            true
          end

          def destroy
            @destroy_called += 1
            true
          end

          def load_json(json_hash)
            self.task_type = json_hash[:task_type]
            self.guid = json_hash[:guid]
            self.priority = json_hash[:priority] || 0
            self.task_data = json_hash[:task_data]
            self.suite_guid = json_hash.fetch(:suite_guid, nil)
            self.time_limit = json_hash.fetch(:time_limit, nil)

            res_strs = (json_hash[:resources] || '').split('|')

            res_strs.each do |res_str|
              task_res = FakeTaskResource.new
              task_res.resource_name = res_str
              @task_resources.push task_res
            end
          end

          def resource_names
            @task_resources.map(&:resource_name)
          end

          def to_h
            {
                type: 'task',
                task_type: task_type,
                guid: guid,
                priority: priority,
                task_data: task_data,
                suite_guid: suite_guid,
                time_limit: time_limit,
                resources: @task_resources.map(&:resource_name).join('|')
            }
          end

          def to_json
            JSON.generate to_h
          end

        end
      end
    end
  end
end

module TEF
  module Development
    module Testing
      module Fakes

        class FakeTaskResource
          attr_accessor :resource_name

          def initialize
            @resource_name = ''
          end
        end
      end
    end
  end
end

module TEF
  module Development
    module Testing
      module Fakes

        class FakeWorkerCollective

          attr_accessor :workers

          def initialize(workers = [])
            @workers = workers
          end

          def available_workers?
            true
          end

        end
      end
    end
  end
end
