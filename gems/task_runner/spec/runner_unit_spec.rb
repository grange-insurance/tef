require 'spec_helper'


describe 'Runner, Unit' do

  clazz = TaskRunner::Runner

  it_should_behave_like 'a loosely configured component', clazz


  describe 'instance level' do

    before(:each) do
      @executor = double('TestExecutor')
      allow(@executor).to receive(:execute).and_return(some_keys: 'some_values')

      @options = {executor: @executor}
      @runner = clazz.new(@options)
      @test_task = {task_data: {task_stuff: 'values'}}
    end


    it_should_behave_like 'a logged component, unit level' do
      let(:clazz) { clazz }
      let(:configuration) { @options }
    end


    it 'does work' do
      expect(@runner).to respond_to(:work)
    end

    it 'works a task' do
      expect(@runner.method(:work).arity).to eq(1)
    end

    it 'needs task data in order to work the task' do
      @test_task.delete(:task_data)

      expect { @runner.work(@test_task) }.to raise_error(ArgumentError, /data/)
    end

    it 'executes the worked task' do
      @runner.work(@test_task)

      expect(@executor).to have_received(:execute).once
    end

    it 'passes along to the executor all important task data' do
      relevant_task_data = {working_directory: 'some/dir', task_command: 'FOO.exe', other_data: {more: 'stuff'}}
      task = {task_data: relevant_task_data, other_data: 'stuff'}

      @runner.work(task)

      expect(@executor).to have_received(:execute).with(hash_including(relevant_task_data)).once
    end

    it 'returns the output of the task execution' do
      output = @runner.work(@test_task)

      expect(output).to eq(some_keys: 'some_values')
    end

  end
end
