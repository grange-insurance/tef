require 'spec_helper'
require 'rspec/mocks/standalone'


def default_options
  {
      callback: double('mock callback'),
      logger: create_mock_logger
  }
end


describe 'Keeper, Unit' do

  clazz = TEF::Keeper::Keeper


  it_should_behave_like 'a strictly configured component', clazz

  it_should_behave_like 'a service component, unit level' do
    let(:clazz) { clazz }
    let(:configuration) { default_options }
  end

  it_should_behave_like 'a receiving component, unit level', clazz, default_options, [:in_queue]
  it_should_behave_like 'a sending component, unit level', clazz, default_options, [:out_queue]

  it_should_behave_like 'a logged component, unit level' do
    let(:clazz) { clazz }
    let(:configuration) { default_options }
  end

  describe 'instance level' do

    before(:each) do
      @options = default_options
      @keeper = clazz.new(@options)
    end


    it 'has a keeper type' do
      expect(@keeper).to respond_to(:keeper_type)
    end

    it 'can be provided a keeper type when created' do
      @options[:keeper_type] = 'some keeper type'
      keeper = clazz.new(@options)

      expect(keeper.keeper_type).to eq('some keeper type')
    end

    it 'defaults to being a generic keeper' do
      @options.delete(:worker_type)
      keeper = clazz.new(@options)

      expect(keeper.keeper_type).to eq('generic')
    end


    describe 'initial setup' do

      it 'can not be initialized without a callback' do
        @options.delete :callback
        expect { clazz.new(@options) }.to raise_error(ArgumentError, /must include/i)
      end

      # todo - add this kind of test to other components with a default queue
      it 'has a default in queue' do
        @options.delete(:in_queue)

        keeper = clazz.new(@options)
        expect(keeper.instance_variable_get(:@in_queue)).to_not be_nil
      end

      it 'does not have a default out queue' do
        @options.delete(:out_queue)

        keeper = clazz.new(@options)
        expect(keeper.instance_variable_get(:@out_queue)).to be_nil
      end

    end

  end
end
