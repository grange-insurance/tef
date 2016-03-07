require 'spec_helper'
require 'rspec/mocks/standalone'


describe 'Keeper, Unit' do

  let(:clazz) { TEF::Keeper::Keeper }
  let(:configuration) { {callback: double('mock callback'),
                         logger: create_mock_logger} }


  it_should_behave_like 'a strictly configured component'
  it_should_behave_like 'a service component, unit level'
  it_should_behave_like 'a receiving component, unit level', [:in_queue]
  it_should_behave_like 'a sending component, unit level', [:output_exchange]
  it_should_behave_like 'a logged component, unit level'
  it_should_behave_like 'a wrapper component, unit level', [:in_queue, :output_exchange]


  describe 'instance level' do

    let(:keeper) { clazz.new(configuration) }


    it 'has a keeper type' do
      expect(keeper).to respond_to(:keeper_type)
    end

    it 'can be provided a keeper type when created' do
      configuration[:keeper_type] = 'some keeper type'
      keeper = clazz.new(configuration)

      expect(keeper.keeper_type).to eq('some keeper type')
    end

    it 'defaults to being a generic keeper' do
      configuration.delete(:worker_type)
      keeper = clazz.new(configuration)

      expect(keeper.keeper_type).to eq('generic')
    end


    describe 'initial setup' do

      it 'can not be initialized without a callback' do
        configuration.delete :callback
        expect { clazz.new(configuration) }.to raise_error(ArgumentError, /must include/i)
      end

      # todo - add this kind of test to other components with a default queue
      it 'has a default in queue' do
        configuration.delete(:in_queue)

        keeper = clazz.new(configuration)
        expect(keeper.instance_variable_get(:@in_queue)).to_not be_nil
      end

      it 'has a default output exchange' do
        configuration.delete(:output_exchange)

        keeper = clazz.new(configuration)
        expect(keeper.instance_variable_get(:@output_exchange)).to_not be_nil
      end

    end

  end
end
