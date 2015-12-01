require 'spec_helper'
require 'rspec/mocks/standalone'


describe 'WorkNode, Integration' do

  let(:clazz) { TEF::Worker::WorkNode }

  let(:mock_logger) { create_mock_logger }
  let(:mock_in_queue) { create_mock_queue }
  let(:mock_out_queue) { create_mock_queue }
  let(:mock_manager_queue) { create_mock_queue }

  let(:configuration) { {logger: mock_logger,
                         in_queue: mock_in_queue,
                         out_queue: mock_out_queue,
                         manager_queue: mock_manager_queue} }
  let(:work_node) { clazz.new(configuration) }


  it_should_behave_like 'a logged component, integration level'
  it_should_behave_like 'a service component, integration level'
  it_should_behave_like 'a receiving component, integration level', [:in_queue]
  it_should_behave_like 'a sending component, integration level', [:out_queue, :manager_queue]
  it_should_behave_like 'a rooted component, integration level'
  it_should_behave_like 'a wrapper component, integration level', [:in_queue, :out_queue, :manager_queue]


  it 'defaults to a basic worker class if one is not provided' do
    configuration.delete(:worker_class)
    work_node = clazz.new(configuration)

    expect(work_node.instance_variable_get(:@worker)).to eq(TEF::Worker::BaseWorker)
  end

  it 'uses its own logging object when creating its worker' do
    mock_logger = create_mock_logger
    configuration[:logger] = mock_logger
    configuration.delete(:worker_class)

    work_node = clazz.new(configuration)

    begin
      work_node.start

      expect(work_node.instance_variable_get(:@worker).logger).to eq(mock_logger)
    ensure
      work_node.stop
    end
  end

  it 'uses its own root location when creating its worker' do
    configuration[:root_location] = 'foo'

    work_node = clazz.new(configuration)

    begin
      work_node.start

      expect(work_node.instance_variable_get(:@worker).root_location).to eq('foo')
    ensure
      work_node.stop
    end
  end

  it 'uses its own name when creating its worker' do
    configuration[:name] = 'foo'

    work_node = clazz.new(configuration)

    begin
      work_node.start

      expect(work_node.instance_variable_get(:@worker).name).to eq('foo')
    ensure
      work_node.stop
    end
  end

end
