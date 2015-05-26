require 'open3'
require 'bunny'
require_relative '../custom_matchers'
require_relative '../../../testing/mocks'
include TefTestingMocks


shared_examples_for 'a service component, integration level' do

  before(:each) do
    @options = configuration.dup

    @mock_logger = create_mock_logger

    @options[:logger] = @mock_logger
    @component = clazz.new(@options)
  end


  it 'starting the service connects it to RabbitMQ' do
    stdout, stderr, status = Open3.capture3('rabbitmqctl list_connections name host port')
    connection_list = stdout.split("\n").slice(1..-2)
    before_count = connection_list.count

    begin
      @component.start

      stdout, stderr, status = Open3.capture3('rabbitmqctl list_connections name host port')
      connection_list = stdout.split("\n").slice(1..-2)
      after_count = connection_list.count

      expect(after_count).to eq(before_count + 1)
    ensure
      @component.stop
    end
  end

  it 'stopping the service disconnects it from RabbitMQ' do
    begin
      @component.start

      stdout, stderr, status = Open3.capture3('rabbitmqctl list_connections name host port')
      connection_list = stdout.split("\n").slice(1..-2)
      before_count = connection_list.count

      @component.stop

      stdout, stderr, status = Open3.capture3('rabbitmqctl list_connections name host port')
      connection_list = stdout.split("\n").slice(1..-2)
      after_count = connection_list.count

      expect(after_count).to eq(before_count - 1)
    ensure
      @component.stop
    end
  end

  it 'can be stopped even if it has not been successfully started' do
    expect { @component.stop }.to_not raise_error
  end


  describe 'configuration' do

    before(:each) do
      @env_location = 'TEF_ENV'
      @url_location = 'TEF_AMQP_URL_TEMP'
      @old_env = ENV[@env_location]
      @old_url = ENV[@url_location]
    end

    # Making sure that our changes don't escape a test and ruin the rest of the suite
    after(:each) do
      ENV[@env_location] = @old_env
      ENV[@url_location] = @old_url
    end

    it 'determines what mode it is in based on an environmental variable' do
      ENV[@env_location] = 'foo'

      expect(@component.send(:tef_env)).to eq('foo')
    end

    it 'is not sensitive to the case of the environmental variable' do
      ENV[@env_location] = 'FoO'

      expect(@component.send(:tef_env)).to eq('foo')
    end

    it 'defaults to development mode if the relevant environmental variable is not set' do
      ENV[@env_location] = nil

      expect(@component.send(:tef_env)).to eq('dev')
    end

    it 'determines the URL for its messaging service based on a (mode dependant) environmental variable' do
      ENV[@env_location] = 'temp'
      ENV['TEF_AMQP_URL_TEMP'] = 'foo'

      expect(@component.send(:bunny_url)).to eq('foo')
    end

    it 'can be provided a username for connecting based on a (mode dependant) environmental variable' do
      ENV[@env_location] = 'temp'
      ENV['TEF_AMQP_USER_TEMP'] = 'foo'

      expect(@component.send(:bunny_username)).to eq('foo')
    end

    it 'can be provided a password for connecting based on a (mode dependant) environmental variable' do
      ENV[@env_location] = 'temp'
      ENV['TEF_AMQP_PASSWORD_TEMP'] = 'foo'

      expect(@component.send(:bunny_password)).to eq('foo')
    end


    describe 'configuration problems' do

      before(:each) do
        @old_method = Bunny::Channel.instance_method(:queue)
      end

      # Making sure that our changes don't escape a test and ruin the rest of the suite
      after(:each) do
        Bunny::Channel.send(:define_method, :queue, @old_method)
      end

      it 'will exit if it cannot determine a URL for its message service' do
        ENV[@env_location] = 'temp'
        ENV[@url_location] = nil

        begin
          expect { @component.start }.to terminate.with_code(1)
        ensure
          @component.stop
        end
      end

      it 'logs if it cannot determine a URL for its message service' do
        ENV[@env_location] = 'temp'
        ENV[@url_location] = nil

        begin
          @component.start
        rescue SystemExit
        ensure
          @component.stop
        end

        expect(@mock_logger).to have_received(:error).with(/missing.+TEF_AMQP_URL_/i)
      end

      it 'will exit if it cannot successfully connect to its message service' do
        ENV[@env_location] = 'temp'
        ENV[@url_location] = 'bad/url'

        begin
          expect { @component.start }.to terminate.with_code(2)
        ensure
          @component.stop
        end
      end

      it 'logs if it cannot successfully connect to its message service' do
        ENV[@env_location] = 'temp'
        ENV[@url_location] = 'bad/url'

        begin
          @component.start
        rescue SystemExit
        ensure
          @component.stop
        end

        expect(@mock_logger).to have_received(:error).with(/failed to connect/i)
      end

    end
  end
end
