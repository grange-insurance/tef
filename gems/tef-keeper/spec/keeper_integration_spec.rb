require 'spec_helper'
require 'rspec/mocks/standalone'


def default_options
  {
      callback: double('mock callback'),
      logger: create_mock_logger
  }
end


describe 'Keeper, Integration' do

  clazz = TEF::Keeper::Keeper

  it_should_behave_like 'a service component, integration level' do
    let(:clazz) { clazz }
    let(:configuration) { default_options }
  end

  it_should_behave_like 'a receiving component, integration level', clazz, default_options, [:in_queue]
  it_should_behave_like 'a sending component, integration level', clazz, default_options, [:out_queue]

  it_should_behave_like 'a logged component, integration level' do
    let(:clazz) { clazz }
    let(:configuration) { default_options }
  end


  describe 'instance level' do

    before(:each) do
      @options = default_options
    end


    it 'defaults to a basic receiver class if one is not provided' do
      @options.delete(:receiver_class)
      keeper = clazz.new(@options)

      expect(keeper.instance_variable_get(:@receiver)).to eq(TEF::Keeper::Receiver)
    end

    it 'uses its own logging object when creating its receiver' do
      mock_logger = create_mock_logger
      @options[:logger] = mock_logger
      @options.delete(:receiver_class)

      keeper = clazz.new(@options)

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
      @options[:callback] = mock_callback

      keeper = clazz.new(@options)
      keeper.start

      receiver = keeper.instance_variable_get(:@receiver)

      expect(receiver.instance_variable_get(:@task_callback)).to eq(mock_callback)
    end

  end
end
