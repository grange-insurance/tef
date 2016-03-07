module TEF
  module Development
    module Testing
      module Mocks

        def create_mock_logger
          mock_thing = double('mock_logger')
          allow(mock_thing).to receive(:info)
          allow(mock_thing).to receive(:debug)
          allow(mock_thing).to receive(:error)
          allow(mock_thing).to receive(:warn)
          allow(mock_thing).to receive(:progname=)

          mock_thing
        end

        def create_mock_connection(created_channel = nil)
          mock_thing = double('mock_connection')
          allow(mock_thing).to receive(:create_channel).and_return(created_channel)

          mock_thing
        end

        def create_mock_channel(exchange = nil)
          mock_thing = double('mock_channel').as_null_object
          allow(mock_thing).to receive(:default_exchange).and_return(exchange) if exchange
          allow(mock_thing).to receive(:generate_consumer_tag).and_return('123456789')
          allow(mock_thing).to receive(:number).and_return(1)
          allow(mock_thing).to receive(:acknowledge)
          allow(mock_thing).to receive(:queue).and_return(exchange)
          allow(mock_thing).to receive(:topic).and_return(exchange)

          mock_thing
        end

        def create_mock_exchange(channel = nil, options = {})
          mock_thing = double('mock_exchange').as_null_object
          allow(mock_thing).to receive(:publish)
          allow(mock_thing).to receive(:name).and_return('test_exchange')
          allow(mock_thing).to receive(:channel).and_return(channel) if channel
          allow(mock_thing).to receive(:opts).and_return(options)

          mock_thing
        end

        def create_mock_properties(specific_properties = {})
          mock_thing = double('mock_properties')
          allow(mock_thing).to receive(:reply_to).and_return(specific_properties.fetch(:reply_to, 'reply_to1'))
          allow(mock_thing).to receive(:correlation_id).and_return(specific_properties.fetch(:correlation_id, 'correlation_id1'))

          mock_thing
        end

        def create_mock_delivery_info
          mock_thing = double('mock_delivery_info')
          allow(mock_thing).to receive(:delivery_tag).and_return('12345')

          mock_thing
        end

        def create_mock_queue(channel = create_mock_channel, options = {})
          mock_thing = double('mock_queue')
          allow(mock_thing).to receive(:name).and_return('mock queue')
          allow(mock_thing).to receive(:publish)
          allow(mock_thing).to receive(:subscribe)
          allow(mock_thing).to receive(:subscribe_with)
          allow(mock_thing).to receive(:channel).and_return(channel)
          allow(mock_thing).to receive(:options).and_return(options)

          mock_thing
        end

      end
    end
  end
end
