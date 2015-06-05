module TEF
  module Development
    module Testing
      module Mocks

        def create_mock_task_queue(*tasks)
          mock_thing = double('mock task queue')
          allow(mock_thing).to receive(:pop).and_return(*tasks)
          allow(mock_thing).to receive(:push)

          mock_thing
        end

        def create_mock_task(task_type = 'mock_task_type')
          mock_thing = double('mock task')
          allow(mock_thing).to receive(:task_type).and_return(task_type)
          allow(mock_thing).to receive(:guid).and_return('12345')
          allow(mock_thing).to receive(:to_h).and_return({
                                                             type: 'task',
                                                             task_type: task_type,
                                                             guid: '12345',
                                                             priority: 1,
                                                             task_data: {},
                                                             suite_guid: '67890',
                                                             time_limit: 50,
                                                             resources: 'foo|bar'
                                                         })

          mock_thing
        end

        def create_mock_worker_collective_class(worker_collective = create_mock_worker_collective)
          mock_thing = double('mock worker collective class')
          allow(mock_thing).to receive(:new).and_return(worker_collective)

          mock_thing
        end

        def create_mock_worker_collective(*workers)
          mock_thing = double('mock worker collective')
          allow(mock_thing).to receive(:get_worker).and_return(workers.first)
          allow(mock_thing).to receive(:available_workers?).and_return(true)
          allow(mock_thing).to receive(:available_worker_types).and_return(['type_1'])

          mock_thing
        end

        def create_mock_worker(worker_type = 'mock_type')
          mock_thing = double('mock worker')
          allow(mock_thing).to receive(:work).and_return(true)
          allow(mock_thing).to receive(:type).and_return(worker_type)
          allow(mock_thing).to receive(:name).and_return('mock worker name')

          mock_thing
        end

        def create_mock_resource_manager_class(resource_manager = create_mock_resource_manager)
          mock_thing = double('mock resource manager class')
          allow(mock_thing).to receive(:new).and_return(resource_manager)

          mock_thing
        end

        def create_mock_resource_manager
          mock_thing = double('mock resource manager')
          allow(mock_thing).to receive(:unavailable_resources).and_return([])

          mock_thing
        end

      end
    end
  end
end
