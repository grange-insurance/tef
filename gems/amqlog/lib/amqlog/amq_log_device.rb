require 'rubygems'
require 'bundler/setup'
require 'logger'
require 'socket'

module Amqlog
  class AMQLogDevice < Logger::LogDevice

    def initialize(connection, channel = nil, exchange = nil)
      @my_channel = !channel
      @my_exchange = !exchange
      @channel  = channel  || AMQP::Channel.new(connection)
      @exchange = exchange || @channel.fanout('log')

      @hostname = Socket.gethostname
    end

    def write(message)
      puts message
      @exchange.publish message if @exchange
    end

    def close
      @exchange.delete if @my_exchange
      @channel.close if @my_channel
    end
  end

end

