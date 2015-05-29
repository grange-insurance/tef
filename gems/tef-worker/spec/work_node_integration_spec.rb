require 'spec_helper'
require 'rspec/mocks/standalone'


def default_options
  {
      logger: create_mock_logger,
      in_queue: create_mock_queue,
      out_queue: create_mock_queue,
      manager_queue: create_mock_queue
  }
end


describe 'WorkNode, Integration' do

  clazz = TEF::Worker::WorkNode

  it_should_behave_like 'a logged component, integration level' do
    let(:clazz) { clazz }
    let(:configuration) { default_options }
  end

  it_should_behave_like 'a service component, integration level' do
    let(:clazz) { clazz }
    let(:configuration) { default_options }
  end

  it_should_behave_like 'a receiving component, integration level', clazz, default_options, [:in_queue]
  it_should_behave_like 'a sending component, integration level', clazz, default_options, [:out_queue, :manager_queue]

  it_should_behave_like 'a rooted component, integration level' do
    let(:clazz) { clazz }
    let(:configuration) { default_options }
  end


  before(:each) do
    @mock_logger = create_mock_logger
    @options = default_options
    @options[:logger] = @mock_logger

    @work_node = clazz.new(@options)
  end


  it 'defaults to a basic worker class if one is not provided' do
    @options.delete(:worker_class)
    work_node = clazz.new(@options)

    expect(work_node.instance_variable_get(:@worker)).to eq(TEF::Worker::BaseWorker)
  end

  it 'uses its own logging object when creating its worker' do
    mock_logger = create_mock_logger
    @options[:logger] = mock_logger
    @options.delete(:worker_class)

    work_node = clazz.new(@options)

    begin
      work_node.start

      expect(work_node.instance_variable_get(:@worker).logger).to eq(mock_logger)
    ensure
      work_node.stop
    end
  end

  it 'uses its own root location when creating its worker' do
    @options[:root_location] = 'foo'

    work_node = clazz.new(@options)

    begin
      work_node.start

      expect(work_node.instance_variable_get(:@worker).root_location).to eq('foo')
    ensure
      work_node.stop
    end
  end

  it 'uses its own name when creating its worker' do
    @options[:name] = 'foo'

    work_node = clazz.new(@options)

    begin
      work_node.start

      expect(work_node.instance_variable_get(:@worker).name).to eq('foo')
    ensure
      work_node.stop
    end
  end

end
