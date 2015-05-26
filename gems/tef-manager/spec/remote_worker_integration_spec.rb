require 'spec_helper'

describe 'RemoteWorker, Integration' do

  clazz = TEF::Manager::RemoteWorker

  describe 'instance level' do

    before(:each) do
      @mock_queue = create_mock_queue
      @mock_resource_manager = double('mock resource manager')

      @options = {
          name: 'test_worker',
          work_queue: @mock_queue, type: 'type_1',
          resource_manager: @mock_resource_manager
      }
    end


    it_should_behave_like 'a logged component, integration level' do
      let(:clazz) { clazz }
      let(:configuration) { @options }
    end

  end
end
