require 'spec_helper'


describe 'Executor, Unit' do

  let(:clazz) { TaskRunner::Executor }
  let(:configuration) { {} }


  it_should_behave_like 'a loosely configured component'
  it_should_behave_like 'a logged component, unit level'


  before(:each) do
    @executor = clazz.new
    @task_data = {working_directory: @default_file_directory,
                  command: 'echo Task is executing...'}
  end

  it 'executes a task' do
    expect(@executor).to respond_to(:execute)
  end

  it 'requires data for the task that it executes' do
    expect(@executor.method(:execute).arity).to eq(1)
  end

  it 'needs to know where to execute the task' do
    @task_data.delete(:working_directory)

    expect { @executor.execute(@task_data) }.to raise_error(ArgumentError, /working/)
  end

  it 'needs to know how to execute the task' do
    @task_data.delete(:command)

    expect { @executor.execute(@task_data) }.to raise_error(ArgumentError, /command/)
  end

  it 'requires that additional task environmental variables are specified in a Hash' do
    @task_data[:env_vars] = 'FOO = BAR'
    expect { @executor.execute(@task_data) }.to raise_error(ArgumentError, /env/)

    @task_data[:env_vars] = {'FOO' => 'BAR'}
    expect { @executor.execute(@task_data) }.to_not raise_error
  end

end
