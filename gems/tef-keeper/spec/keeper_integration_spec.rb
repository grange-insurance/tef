require 'spec_helper'
require 'rspec/mocks/standalone'


describe 'Keeper, Integration' do

  let(:clazz) { TEF::Keeper::Keeper }
  let(:configuration) { {callback: double('mock callback'),
                         logger: create_mock_logger} }


  it_should_behave_like 'a service component, integration level'
  it_should_behave_like 'a receiving component, integration level', [:in_queue]
  it_should_behave_like 'a sending component, integration level', [:output_exchange]
  it_should_behave_like 'a logged component, integration level'
  it_should_behave_like 'a wrapper component, integration level', [:in_queue, :output_exchange]


  describe 'instance level' do


    it 'defaults to a basic receiver class if one is not provided' do
      configuration.delete(:receiver_class)
      keeper = clazz.new(configuration)

      expect(keeper.instance_variable_get(:@receiver)).to eq(TEF::Keeper::Receiver)
    end

    it 'uses its own logging object when creating its receiver' do
      mock_logger = create_mock_logger
      configuration[:logger] = mock_logger
      configuration.delete(:receiver_class)

      keeper = clazz.new(configuration)

      # todo - will need to put the protection back if keeper starts to use heartbeats
      #begin
      keeper.start

      expect(keeper.instance_variable_get(:@receiver).logger).to eq(mock_logger)
      #ensure
      #  keeper.stop
      #end
    end

    it 'passes along its callback for use by the receiver' do
      mock_callback = double('mock callback')
      configuration[:callback] = mock_callback

      keeper = clazz.new(configuration)
      keeper.start

      receiver = keeper.instance_variable_get(:@receiver)

      expect(receiver.instance_variable_get(:@task_callback)).to eq(mock_callback)
    end

  end
end
