module TefTestingFakes

  def create_fake_exchange
    FakeExchange.new
  end

  def create_fake_channel(exchange = create_fake_exchange)
    FakeChannel.new(exchange)
  end

  def create_fake_publisher(channel)
    FakePublisher.new(channel)
  end

end


module TefTestingFakes
  class FakeExchange

    attr_reader :messages

    def initialize
      @messages = []
    end

    def publish(message, *args)
      @messages << message
    end

  end
end

module TefTestingFakes
  class FakeChannel

    def initialize(exchange)
      @exchange = exchange
    end

    def generate_consumer_tag
      '123456789'
    end

    def number
      12345
    end

    def queue(queue_name, options = {})
      FakePublisher.new(self, queue_name)
    end

  end
end

class FakePublisher
  attr_reader :channel, :name

  def initialize(chan, name = 'fake publisher')
    @channel = chan
    @name = name
  end

  def subscribe(_opts = {
      :ack             => false,
      :exclusive       => false,
      :block           => false,
      :on_cancellation => nil
  }, &block)
    @callback = block
  end

  def subscribe_with(consumer, *args)
    @consumer = consumer
  end

  def call(*args)
    raise('Publisher has not been subscribed to yet') unless @callback || @consumer
    @callback.call(*args) if @callback
    @consumer.handle_delivery(*args) if @consumer
  end

end
