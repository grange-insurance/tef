require 'spec_helper'


describe 'Runner, Unit' do

  let(:clazz) { TaskRunner::Runner }

  it_should_behave_like 'a loosely configured component'


  describe 'instance level' do

    let(:mock_executor) { mock = double('TestExecutor')
                          allow(mock).to receive(:execute).and_return(some_keys: 'some_values')
                          mock }
    let(:configuration) { {executor: mock_executor} }
    let(:runner) { clazz.new(configuration) }
    let(:test_task) { {task_data: {task_stuff: 'values'}} }


    it_should_behave_like 'a logged component, unit level'


    it 'does work' do
      expect(runner).to respond_to(:work)
    end

    it 'works a task' do
      expect(runner.method(:work).arity).to eq(1)
    end

    it 'needs task data in order to work the task' do
      test_task.delete(:task_data)

      expect { runner.work(test_task) }.to raise_error(ArgumentError, /data/)
    end

    it 'executes the worked task' do
      runner.work(test_task)

      expect(mock_executor).to have_received(:execute).once
    end

    it 'passes along to the executor all important task data' do
      relevant_task_data = {working_directory: 'some/dir', task_command: 'FOO.exe', other_data: {more: 'stuff'}}
      task = {task_data: relevant_task_data, other_data: 'stuff'}

      runner.work(task)

      expect(mock_executor).to have_received(:execute).with(hash_including(relevant_task_data)).once
    end

    it 'returns the output of the task execution' do
      output = runner.work(test_task)

      expect(output).to eq(some_keys: 'some_values')
    end

  end
end
