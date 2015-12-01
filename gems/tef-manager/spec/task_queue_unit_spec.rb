require 'spec_helper'
require 'json'

describe 'TaskQueue, Unit' do

  let(:clazz) { TEF::Manager::TaskQueue }

  it_should_behave_like 'a strictly configured component'


  describe 'instance level' do

    let(:mock_logger) { create_mock_logger }
    let(:mock_input_queue) { create_mock_queue }
    let(:configuration) { {logger: mock_logger,
                           input_queue: mock_input_queue} }
    let(:task_queue) { clazz.new(configuration) }


    it_should_behave_like 'a logged component, unit level'


    it 'does not change the progname on the logger' do
      expect(mock_logger).not_to receive(:progname=)
    end

    it 'can store a task' do
      expect(task_queue).to respond_to(:push)
    end

    it 'needs a task to store' do
      expect(task_queue.method(:push).arity).to eq(1)
    end

    it 'can retrieve a task' do
      expect(task_queue).to respond_to(:pop)
    end

    it 'retrieves a task based on resource availability and worker types' do
      expect(task_queue.method(:pop).arity).to eq(2)
    end

  end
end
