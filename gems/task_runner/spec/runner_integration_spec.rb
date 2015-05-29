require 'spec_helper'


describe 'Runner, Integration' do

  clazz = TaskRunner::Runner


  describe 'instance level' do

    before(:each) do
      @executor = double('TestExecutor')
      allow(@executor).to receive(:execute).and_return(some_keys: 'some_values')

      @options = {executor: @executor}
      @runner = clazz.new(@options)
    end


    it_should_behave_like 'a logged component, integration level' do
      let(:clazz) { clazz }
      let(:configuration) { @options }
    end


    it 'defaults to a basic executor if one is not provided' do
      @options.delete(:executor)
      runner = clazz.new(@options)

      expect(runner.instance_variable_get(:@executor)).to be_a(TaskRunner::Executor)
    end

    it 'uses its own logging object when providing a default executor' do
      mock_logger = create_mock_logger
      @options[:logger] = mock_logger
      @options.delete(:executor)

      runner = clazz.new(@options)

      expect(runner.instance_variable_get(:@executor).logger).to eq(mock_logger)
    end


  end
end
