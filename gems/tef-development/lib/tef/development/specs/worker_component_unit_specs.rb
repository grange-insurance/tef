shared_examples_for 'a worker component, unit level' do

  it_should_behave_like 'a configured component'


  # 'clazz' must be defined by an including scope
  # 'configuration' must be defined by an including scope

  let(:mock_logger) { create_mock_logger }
  let(:test_task) { {type: "task",
                     task_type: "echo",
                     guid: "12345",
                     priority: 1,
                     resources: "foo",
                     time_limit: 10,
                     suite_guid: "67890",
                     task_data: {command: "echo 'Hello'"},
                     root_location: @default_file_directory} }
  let(:component) { clazz.new(configuration) }


  it 'can be started' do
    expect(component).to respond_to(:start)
  end

  it 'can be stopped' do
    expect(component).to respond_to(:stop)
  end

  it 'has a root location' do
    expect(component).to respond_to(:root_location)
  end

  it 'can be provided with a root location when created' do
    configuration[:root_location] = 'some root location'
    component = clazz.new(configuration)

    expect(component.root_location).to eq('some root location')
  end

  it 'has a worker type' do
    expect(component).to respond_to(:worker_type)
  end

  it 'can be provided a worker type when created' do
    configuration[:worker_type] = 'some worker type'
    worker = clazz.new(configuration)

    expect(worker.worker_type).to eq('some worker type')
  end

  it 'has a status interval' do
    expect(component).to respond_to(:status_interval)
  end

  it 'can be provided a status interval when created' do
    configuration[:status_interval] = 99
    worker = clazz.new(configuration)

    expect(worker.status_interval).to eq(99)
  end

  it 'has a default status interval if one is not provided' do
    configuration.delete(:status_interval)
    worker = clazz.new(configuration)

    expect(worker.status_interval).to eq(20)
  end

  it 'only accepts integers as status intervals' do
    configuration[:status_interval] = '99'

    expect { clazz.new(configuration) }.to raise_error(ArgumentError, /only.+integer/i)
  end

  it 'has a status' do
    expect(component).to respond_to(:status)
  end

  it 'can change its status' do
    expect(component).to respond_to(:status=)

    component.status = :some_status
    expect(component.status).to eq(:some_status)
    component.status = :some_other_status
    expect(component.status).to eq(:some_other_status)
  end

  it 'starts with an idle status' do
    expect(component.status).to eq(:idle)
  end

  it 'has a name' do
    expect(component).to respond_to(:name)
  end

  it 'can change its name' do
    expect(component).to respond_to(:name=)

    component.name = :some_name
    expect(component.name).to eq(:some_name)
    component.name = :some_other_name
    expect(component.name).to eq(:some_other_name)
  end

  it 'starts with a default name' do
    expect(component.name).to_not be_nil
  end

  it 'can be provided a name when created' do
    configuration[:name] = 'foo'
    worker = clazz.new(configuration)

    expect(worker.name).to eq('foo')
  end

  describe 'doing work' do

    it 'can do work' do
      expect(component).to respond_to(:work)
    end

    it 'works a task' do
      expect(component.method(:work).arity).to eq(1)
    end

    it 'complains if a worked task does not include task data' do
      test_task.delete(:task_data)

      expect { component.work(test_task) }.to raise_error(ArgumentError, /must include.*task.data/i)
    end

    it "complains if worked task's task data is not a hash" do
      test_task[:task_data] = 'foo'

      expect { component.work(test_task) }.to raise_error(ArgumentError, /task_data.*must be a Hash.*was #{test_task[:task_data].class}/i)
    end

    it 'logs the tasks the it works' do
      configuration[:logger] = mock_logger
      component = clazz.new(configuration)

      component.work(test_task)

      expect(mock_logger).to have_received(:info).at_least(:once).with(/task received.*#{test_task[:guid]}/i)
    end

    it 'logs the contents of the worked task' do
      configuration[:logger] = mock_logger
      component = clazz.new(configuration)

      # Deep cloning the task since it will get modified while being worked
      original_task = Marshal.load(Marshal.dump(test_task))
      component.work(test_task)

      expect(mock_logger).to have_received(:info).with(/task payload.*#{Regexp.escape(original_task.to_s)}/i)
    end

    it 'delegates working a task to its provided task runner' do
      # todo - this runner mocking needs to be done for all tests or else these are integration tests
      mock_task_runner = double('mock task runner')
      allow(mock_task_runner).to receive(:work)
      configuration[:runner] = mock_task_runner
      component = clazz.new(configuration)

      component.work(test_task)

      expect(mock_task_runner).to have_received(:work).with(test_task)
    end

  end

end
