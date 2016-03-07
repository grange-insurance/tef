require 'spec_helper'

describe 'BaseWorker, Integration' do

  clazz = TEF::Worker::BaseWorker


  before(:all) do
    @bunny_url = ENV["TEF_AMQP_URL_#{@tef_env}"]
    @bunny_connection = Bunny.new(@bunny_url)
    @bunny_connection.start
  end

  before(:each) do
    @mock_manager_queue = create_mock_queue
    @in_queue = create_mock_queue

    @options = {root_location: @default_file_directory, in_queue: @in_queue, output_exchange: create_mock_exchange, manager_queue: @mock_manager_queue}
    @worker = clazz.new(@options)
  end

  it_should_behave_like 'a logged component, integration level' do
    let(:clazz) { clazz }
    let(:configuration) { @options }
  end

  it_should_behave_like 'a worker component, integration level' do
    let(:clazz) { clazz }
    let(:configuration) { @options }
  end


  it 'runner defaults to a basic runner if one is not provided' do
    @options.delete(:runner)
    component = clazz.new(@options)

    expect(component.instance_variable_get(:@runner)).to be_a(TaskRunner::Runner)
  end

  it 'should be listening to its inbound queue once it has been started' do
    begin
      @worker.start

      expect(@in_queue).to have_received(:subscribe_with)
    ensure
      @worker.stop
    end
  end

end
