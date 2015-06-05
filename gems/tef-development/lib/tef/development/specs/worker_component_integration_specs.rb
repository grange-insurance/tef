require 'json'
require_relative '../testing/fakes'
include TEF::Development::Testing::Fakes

shared_examples_for 'a worker component, integration level' do

  before(:each) do
    @test_task = {
        type: "task",
        task_type: "echo",
        guid: "12345",
        priority: 1,
        resources: "foo",
        time_limit: 10,
        suite_guid: "67890",
        task_data: {command: "echo 'Hello'",
                    root_location: @default_file_directory}
    }

    @options = configuration.dup
    @component = clazz.new(@options)
  end


  it 'provides a default runner if one is not provided' do
    @options.delete(:runner)
    component = clazz.new(@options)

    expect(component.instance_variable_get(:@runner)).to_not be_nil
  end

  it 'uses its own logging object when providing a default runner' do
    mock_logger = create_mock_logger
    @options[:logger] = mock_logger
    @options.delete(:runner)

    component = clazz.new(@options)

    expect(component.instance_variable_get(:@runner).logger).to eq(mock_logger)
  end

  it 'complains if it cannot determine a root location at task execution time' do
    @options[:root_location] = nil
    @test_task[:task_data].delete(:root_location)
    component = clazz.new(@options)

    expect { component.work(@test_task) }.to raise_error(ArgumentError, /root.location.*cannot be determined.*provided.*variable/i)
  end

  it 'can be stopped even if it has not been successfully started' do
    expect { @component.stop }.to_not raise_error
  end


  describe 'worker heartbeat' do

    before(:each) do
      @test_interval = 1


      # This is the one that will be getting the periodic heartbeat updates
      @mock_manager_copy = create_mock_queue
      mock_new_channel = create_mock_channel(@mock_manager_copy)
      mock_connection = create_mock_connection(mock_new_channel)
      mock_channel = create_mock_channel
      allow(mock_channel).to receive(:connection).and_return(mock_connection)


      # This one gets the non-heartbeat updates
      @mock_manager_queue = create_mock_queue(mock_channel)
      @options[:status_interval] = @test_interval
      @options[:manager_queue] = @mock_manager_queue

      @component = clazz.new(@options)
    end

    it "starting the service starts the worker's heartbeat" do
      expect(@mock_manager_copy).to_not have_received(:publish) # Not beating

      begin
        @component.start

        # Multi-threadedness is not an exact science. This should be enough of a buffer that even particularly
        # sleepy threads have time to do their thing.
        sleep(@test_interval + 0.1)


        expect(@mock_manager_copy).to have_received(:publish).at_least(:once) # Now beating
      ensure
        # Don't want the heartbeat thread to keep going once the test is over
        @component.stop
      end
    end

    it "stopping the service stops the worker's heartbeat" do
      expect(@mock_manager_copy).to_not have_received(:publish) # Not beating

      begin
        @component.start

        # Multi-threadedness is not an exact science. This should be enough of a buffer that even particularly
        # sleepy threads have time to do their thing.
        sleep(@test_interval + 0.1)

        @component.stop

        # And another interval to give it a chance to not stop
        sleep(@test_interval + 0.1)

        expect(@mock_manager_copy).to have_received(:publish).once # Should have had time for only one beat before being stopped
      ensure
        # Don't want the heartbeat thread to keep going once the test is over
        @component.stop
      end
    end

    it 'heartbeats at least once before waiting for its status interval' do
      really_long_test_interval = 600
      @options[:status_interval] = really_long_test_interval

      component = clazz.new(@options)

      begin
        component.start

        # Note: This is the only 'heartbeat' that goes to the original manager queue. All others should be going to the copy queue.
        expect(@mock_manager_queue).to have_received(:publish).once
      ensure
        component.stop
      end
    end

    it 'heartbeats only once per status interval' do
      expect(@mock_manager_copy).to_not have_received(:publish) # Never beat yet

      begin
        @component.start

        # Multi-threadedness is not an exact science. This should be enough of a buffer that even particularly
        # sleepy threads have time to do their thing.
        sleep 0.25

        5.times do |interval_count|
          expect(@mock_manager_copy).to have_received(:publish).exactly(interval_count).times
          sleep @test_interval
        end
      ensure
        # Don't want the heartbeat thread to keep going once the test is over
        @component.stop
      end
    end

    it 'heartbeat will stop on its own if worker can no longer be stopped (e.g. worker node/process crashes)' do
      skip("This one last. Will need to actually make sure that it is a problem first by playing with a live worker (so I'll need to get the binary working again...)")
    end

    it 'identifies itself as busy while working a task' do
      execution_intervals = 2
      fake_in_queue = create_fake_publisher(create_mock_channel)
      @options[:in_queue] = fake_in_queue

      component = clazz.new(@options)

      # Just going to ping the local host for a few seconds (plus one time since the first ping is immediate)
      @test_task[:task_data][:command] = "ping -n #{execution_intervals + 1} 127.0.0.1"

      begin
        component.start
        fake_in_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))

        received_messages = []
        expect(@mock_manager_copy).to have_received(:publish).at_least(:once) do |arg|
          received_messages << arg
        end

        received_messages.select! { |message| message =~ /"status":"working"/ }

        expect(received_messages.count).to be >= (execution_intervals) # Initial work heartbeat plus interval beats
      ensure
        # Don't want the heartbeat thread to keep going once the test is over
        component.stop
      end
    end

    it 'updates its manager when it begins working a task (instead of waiting until the next status interval)' do
      really_long_test_interval = 600
      fake_in_queue = create_fake_publisher(create_mock_channel)
      @options[:status_interval] = really_long_test_interval
      @options[:in_queue] = fake_in_queue

      component = clazz.new(@options)

      begin
        component.start
        fake_in_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))

        received_messages = []
        expect(@mock_manager_queue).to have_received(:publish).at_least(:once) do |arg|
          received_messages << arg
        end

        received_messages.select! { |message| message =~ /"status":"working"/ }

        expect(received_messages.count).to be >= 1 # Initial work heartbeat plus interval beats
      ensure
        # Don't want the heartbeat thread to keep going once the test is over
        component.stop
      end
    end

    it 'goes back to being idle once it is finished working a task' do
      execution_intervals = 2
      fake_in_queue = create_fake_publisher(create_mock_channel)
      @options[:in_queue] = fake_in_queue

      component = clazz.new(@options)

      begin
        component.start
        fake_in_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))

        # Give it some time to be done working and go back to an idle state
        sleep((@test_interval * execution_intervals) + @test_interval)

        explicit_messages = []
        expect(@mock_manager_queue).to have_received(:publish).at_least(:once) do |arg|
          explicit_messages << arg
        end
        explicit_messages.select! { |message| message =~ /"status":"idle"/ }

        heartbeat_messages = []
        expect(@mock_manager_copy).to have_received(:publish).at_least(:once) do |arg|
          heartbeat_messages << arg
        end
        heartbeat_messages.select! { |message| message =~ /"status":"idle"/ }


        expect(explicit_messages.count + heartbeat_messages.count).to be >= (execution_intervals + 2) # Initial update, work finish update, plus post-work heartbeat updates
      ensure
        # Don't want the heartbeat thread to keep going once the test is over
        component.stop
      end
    end

    it 'updates its manager when it finishes working a task (instead of waiting until the next status interval)' do
      really_long_test_interval = 600
      fake_in_queue = create_fake_publisher(create_mock_channel)
      @options[:status_interval] = really_long_test_interval
      @options[:in_queue] = fake_in_queue

      component = clazz.new(@options)

      begin
        component.start
        fake_in_queue.call(create_mock_delivery_info, create_mock_properties, JSON.generate(@test_task))

        received_messages = []
        expect(@mock_manager_queue).to have_received(:publish).at_least(:once) do |arg|
          received_messages << arg
        end

        received_messages.select! { |message| message =~ /"status":"idle"/ }

        expect(received_messages.count).to eq(2) # Initial startup update plus work finish update
      ensure
        # Don't want the heartbeat thread to keep going once the test is over
        component.stop
      end
    end

  end
end
