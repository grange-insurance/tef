require 'spec_helper'
describe 'Receiver, Integration' do

  clazz = TEF::Keeper::Receiver


  describe 'instance level' do

    before(:each) do
      @mock_in_queue = create_mock_queue

      @options = {
          in_queue: @mock_in_queue,
          out_queue: create_mock_queue,
          callback: double('mock callback')
      }

      @receiver = clazz.new(@options)
    end

    it_should_behave_like 'a logged component, integration level' do
      let(:clazz) { clazz }
      let(:configuration) { @options }
    end


    it 'should be listening to its inbound queue once it has been started' do
      begin
        @receiver.start

        expect(@mock_in_queue).to have_received(:subscribe_with)
      ensure
        @receiver.stop
      end
    end

  end
end
