require 'spec_helper'


describe 'Executor, Integration' do

  clazz = TaskRunner::Executor


  it_should_behave_like 'a logged component, integration level' do
    let(:clazz) { clazz }
    let(:configuration) { {} }
  end


  before(:each) do
    @mock_logger = create_mock_logger

    @options = {logger: @mock_logger}
    @executor = clazz.new(@options)
  end


  # Running these tests in a location that is wiped in between tests since
  # they may fail in a dirty state
  before(:each) do
    @old_wd = Dir.pwd
    Dir.chdir @default_file_directory
  end

  # Of course, the location swap also needs to clean up after itself
  after(:each) do
    Dir.chdir @old_wd
  end

  it 'executes the task from the specified location' do
    new_directory = 'new_dir'
    working_directory1 = @default_file_directory
    working_directory2 = "#{working_directory1}/#{new_directory}"
    result_directory1 = "#{working_directory1}/#{new_directory}"
    result_directory2 = "#{working_directory2}/#{new_directory}"

    task_data = {command: "mkdir #{new_directory}"}


    fail('Location to be tested for already exists.') if File.exist?(result_directory2)
    fail('Location to be tested for already exists.') if File.exist?(result_directory1)

    task_data[:working_directory] = working_directory1
    @executor.execute(task_data)

    task_data[:working_directory] = working_directory2
    @executor.execute(task_data)


    expect(File.directory?(result_directory1)).to be true
    expect(File.directory?(result_directory2)).to be true
  end

  it 'raises an error if the location does not exist' do
    task_data = {working_directory: '/this/does/not/exist',
                 command: 'echo Task is executing...'}

    expect { @executor.execute(task_data) }.to raise_error(ArgumentError, /must exist/)
  end

  it 'sets any environmental variables defined by the task when executing' do
    env_var = 'tef_task_runner_executor_var'
    ENV[env_var] = ''

    directory_1 = 'dir_1'
    directory_2 = 'dir_2'
    working_directory = @default_file_directory
    result_directory = "#{working_directory}/#{directory_2}"

    task_data = {working_directory: working_directory,
                 env_vars: {env_var => 'second'},
                 command: "ruby -e \"ENV['#{env_var}'] == 'second' ? system('mkdir #{directory_2}') : system('mkdir #{directory_1}')\""}

    fail('Location to be tested for already exists.') if File.exist?(result_directory)

    @executor.execute(task_data)

    expect(File.directory?(result_directory)).to be true
  end

  describe 'execution output' do

    before(:each) do
      @task_data = {working_directory: @default_file_directory,
                    command: 'echo Task is executing...'}
    end


    it 'execution output contains the stdout, stderr, and status of the executed task' do
      output = @executor.execute(@task_data)

      expect(output).to be_a(Hash)
      expect(output.key?(:stdout)).to be true
      expect(output.key?(:stderr)).to be true
      expect(output.key?(:status)).to be true
    end

    it 'correctly returns stdout' do
      message = 'Hello stdout!'
      @task_data[:command] = "echo #{message}"

      output = @executor.execute(@task_data)

      expect(output[:stdout]).to include(message)
    end

    it 'correctly returns stderr' do
      error = 'The sky is falling!'
      @task_data[:command] = "ruby -e \"fail('#{error}')\""

      output = @executor.execute(@task_data)

      expect(output[:stderr]).to include(error)
    end

    it 'correctly returns status' do
      @task_data[:command] = 'ruby -e "exit(42)"'

      output = @executor.execute(@task_data)

      expect(output[:status]).to be_a(Process::Status)
      expect(output[:status].exitstatus).to eq(42)
    end

    it 'logs the task that it is executing' do
      @executor.execute(@task_data)

      expect(@mock_logger).to have_received(:debug).with(/executing task:/i)
    end

  end
end
