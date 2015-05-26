require 'spec_helper'


# Note: Heavy use of fakes for DB objects here. Makes me wonder if making some of these
# tests be full on integration tests that use an actual DB instead would help us detect
# problems sooner.


describe 'RemoteWorker, Unit' do
  clazz = TEF::Manager::RemoteWorker

  it_should_behave_like 'a strictly configured component', clazz

  describe 'class level' do
    before(:each) do
      @mock_queue = create_mock_queue
      @mock_resource_manager = double('mock resource manager')

      @options = {
          name: 'test_worker',
          work_queue: @mock_queue,
          type: 'type_1',
          resource_manager: @mock_resource_manager
      }

      @worker = clazz.new(@options)
    end

    it 'has a name' do
      expect(@worker).to respond_to(:name)
    end

    it 'can be provided with a name upon creation' do
      @options[:name] = 'foo'
      worker = clazz.new(@options)

      expect(worker.name).to eq('foo')
    end

    it 'will complain if not provided a with a name' do
      @options.delete(:name)

      expect { clazz.new(@options) }.to raise_error(ArgumentError, /name.*must be provided/i)
    end

    it 'has a work queue' do
      expect(@worker).to respond_to(:work_queue)
    end

    it 'can be provided with a work queue upon creation' do
      @options[:work_queue] = @mock_queue
      worker = clazz.new(@options)

      expect(worker.work_queue).to eq(@mock_queue)
    end

    it 'will complain if not provided a with a work queue' do
      @options.delete(:work_queue)

      expect { clazz.new(@options) }.to raise_error(ArgumentError, /work.queue.*must be provided/i)
    end

    it 'has a type' do
      expect(@worker).to respond_to(:type)
    end

    it 'can be provided with a type upon creation' do
      @options[:type] = 'foo'
      worker = clazz.new(@options)

      expect(worker.type).to eq('foo')
    end

    it 'will complain if not provided a with a type' do
      @options.delete(:type)

      expect { clazz.new(@options) }.to raise_error(ArgumentError, /type.*must be provided/i)
    end

    it 'has an update interval' do
      expect(@worker).to respond_to(:update_interval)
    end

    it 'can be provided with an update interval upon creation' do
      @options[:update_interval] = 12345
      worker = clazz.new(@options)

      expect(worker.update_interval).to eq(12345)
    end

    it 'sets a default update interval of 30 seconds if one is not provided' do
      @options.delete(:update_interval)

      worker = clazz.new(@options)

      expect(worker.update_interval).to eq(30)
    end

    it 'has time limit' do
      expect(@worker).to respond_to(:time_limit)
    end

    it 'can be provided with a time limit upon creation' do
      @options[:time_limit] = 12345
      worker = clazz.new(@options)

      expect(worker.time_limit).to eq(12345)
    end

    it 'sets a default time limit of 600 seconds if one is not provided' do
      @options.delete(:time_limit)

      worker = clazz.new(@options)

      expect(worker.time_limit).to eq(600)
    end

    it 'can be provided with a resource manager upon creation' do
      @options[:resource_manager] = :some_manager
      worker = clazz.new(@options)

      expect(worker.instance_variable_get(:@resource_manager)).to eq(:some_manager)
    end

    it 'will complain if not provided a with a type' do
      @options.delete(:resource_manager)

      expect { clazz.new(@options) }.to raise_error(ArgumentError, /resource.manager.*must be provided/i)
    end

    it 'has a task' do
      expect(@worker).to respond_to(:task)
    end

    it 'has a last update time' do
      expect(@worker).to respond_to(:last_update_time)
    end

    it 'has a status' do
      expect(@worker).to respond_to(:status)
    end

    it 'can change its status' do
      expect(@worker).to respond_to(:status=)
    end

    it 'can do work' do
      expect(@worker).to respond_to(:work)
    end

    it 'works a task' do
      expect(clazz.instance_method(:work).arity).to eq(1)
    end

  end

  describe 'instance level' do
    before(:each) do
      @test_task = {type: 'task',
                    task_type: 'type_1',
                    guid: SecureRandom.uuid,
                    priority: 5,
                    resources: 'res_1|res_2|res_3',
                    task_data: 'data',
                    time_limit: 1
      }

      @fake_task = FakeTask.new
      @mock_queue = create_mock_queue
      @mock_resource_manager = double('mock resource manager')
      allow(@mock_resource_manager).to receive(:add_ref).and_return(true)
      allow(@mock_resource_manager).to receive(:remove_ref)

      @options = {
          name: 'test_worker',
          work_queue: @mock_queue,
          type: 'type_1',
          resource_manager: @mock_resource_manager
      }

      @worker = clazz.new(@options)
    end

    it_should_behave_like 'a logged component, unit level' do
      let(:clazz) { clazz }
      let(:configuration) { @options }
    end

    it 'knows how many seconds have passed since it was last updated' do
      expect(@worker).to respond_to(:seconds_since_last_update)
    end

    describe 'initial setup' do

      it 'sets the last_update_time to the current time when created' do
        # todo - insert timecop gem here...
        # Close enough for the purposes of testing without being too fragile
        expect(@worker.seconds_since_last_update).to be <= 1
      end

    end

    describe 'working a task' do

      it 'sets its task as the task that it is working' do
        expect(@worker.task).to be_nil

        @worker.work(@fake_task)

        expect(@worker.task).to eq(@fake_task)
      end

      it "uses the task's time limit instead of the worker's time limit if one is provided" do
        @fake_task.time_limit = nil

        @worker.work(@fake_task)

        expect(@worker.time_limit).to eq(600)

        @fake_task.time_limit = 123
        expect(@worker.time_limit).to eq(123)
      end

      it 'publishes tasks to the actual worker via its work queue' do
        task = @fake_task

        @worker.work(task)

        expect(@mock_queue).to have_received(:publish).with(task.to_json)
      end

      it 'records the dispatch time of the worked task' do
        task = @fake_task

        @worker.work(task)

        expect(task.dispatched).to be_a(Time)
        expect(task.save_called).to eq(1) # Magic number that is checking for a DB update since this isn't an integration test where it would be inherently tested.
      end

      it 'reserves resources when asked to do work' do
        @worker.work(@fake_task)
        expect(@mock_resource_manager).to have_received(:add_ref)
      end

      it 'will not work a task if it cannot reserve resources' do
        allow(@mock_resource_manager).to receive(:add_ref).and_return(false)
        task = @fake_task

        result = @worker.work(task)

        expect(task.dispatched).to be_nil
        expect(@worker.task).to be_nil
        expect(task.save_called).to eq(0) # DB shouldn't have gotten hit
        expect(@mock_queue).to_not have_received(:publish)
      end

      it 'returns false if it fails to work (e.g. if it cannot reserve resources)' do
        allow(@mock_resource_manager).to receive(:add_ref).and_return(false)
        task = @fake_task

        result = @worker.work(task)

        expect(result).to be false
      end

      it 'returns true if nothing goes wrong' do
        allow(@mock_resource_manager).to receive(:add_ref).and_return(true)
        task = @fake_task

        result = @worker.work(task)

        expect(result).to be true
      end

      it 'releases resources when a worker fails to pick up a dispatched task' do
        task = @fake_task

        # Calling work will set the worker to :dispatched
        @worker.work(task)

        # Setting it to idle before it goes to :working simulates a worker failing to pick up the task
        @worker.status = :idle

        expect(@mock_resource_manager).to have_received(:remove_ref)
        expect(task.dispatched).to be_nil
        expect(@worker.task).to be_nil
      end

      it 'releases resources when a worker starts working but fails to send a done status' do
        task = @fake_task

        # Calling work will set the worker to :dispatched
        @worker.work(task)

        # Simulating a worker that starts but doesn't finish working its task
        @worker.status = :working
        @worker.status = :idle

        expect(@mock_resource_manager).to have_received(:remove_ref)
        expect(task.dispatched).to be_nil
        expect(@worker.task).to be_nil
        expect(task.save_called).to eq(2) # Magic number that is checking for the two DB updates (the dispatch value updates) since this isn't an integration test where it would be inherently tested.
      end

      it 'deletes tasks once completed' do
        task = @fake_task
        @worker.work(task)

        # The happy path through the status state machine
        @worker.status = :working
        @worker.status = :task_complete

        expect(@mock_resource_manager).to have_received(:remove_ref).with(task.resource_names)
        expect(task.destroy_called).to eq(1)
        expect(@worker.task).to be_nil
      end

    end


    describe 'worker status' do

      it 'has a default status of idle' do
        expect(@worker.status).to eq(:idle)
      end

      it 'changes to the dispatched status when asked to do work' do
        @worker.work(@fake_task)
        expect(@worker.status).to eq(:dispatched)
      end

      it 'is considered stalled if working a task takes too long' do
        @fake_task.time_limit = 1

        @worker.work(@fake_task)
        sleep @fake_task.time_limit + 1

        expect(@worker.status).to eq(:stalled)
      end

      it 'is does not stall if it not working a task (i.e. is idling)' do
        interval = 1
        @options[:time_limit] = interval
        worker = clazz.new(@options)

        sleep interval + 1

        expect(worker.status).to eq(:idle)
      end

      it 'is considered missing if it has not been updated within the time span of its update interval' do
        interval = 1
        @options[:update_interval] = interval
        worker = clazz.new(@options)

        sleep interval + 0.1

        expect(worker.status).to eq(:missing)
      end

    end


    it 'can return a hash representation of itself' do
      expect(@worker).to respond_to(:to_h)
      expect(@worker.to_h).to be_a(Hash)
    end

    it 'includes important worker information in its hash output' do
      worker_hash = @worker.to_h

      expect(worker_hash[:status]).to eq(:idle)
      expect(worker_hash[:name]).to eq('test_worker')
      expect(worker_hash[:work_queue]).to eq('mock queue')
      expect(worker_hash[:task]).to eq(nil)
    end

    it 'includes the task in the hash if there is a task being worked' do
      @fake_task.load_json(@test_task)
      @worker.work(@fake_task)

      worker_hash = @worker.to_h

      expect(worker_hash[:status]).to eq(:dispatched)
      expect(worker_hash[:name]).to eq('test_worker')
      expect(worker_hash[:work_queue]).to eq('mock queue')

      # This feels unnecessarily specific, like we are testing the other object instead.
      # Perhaps something more like this?:   expect(worker_hash[:task]).to_not be_nil

      expect(worker_hash[:task][:type]).to eq('task')
      expect(worker_hash[:task][:task_type]).to eq('type_1')
      expect(worker_hash[:task][:guid]).not_to be_nil
      expect(worker_hash[:task][:priority]).to eq(5)
      expect(worker_hash[:task][:resources]).to eq('res_1|res_2|res_3')
      expect(worker_hash[:task][:task_data]).to eq('data')
      expect(worker_hash[:task][:time_limit]).to eq(1)
    end

  end

end
