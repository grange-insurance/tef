require_relative 'messaging_component_integration_specs'

require_relative '../testing/mocks'
include TEF::Development::Testing::Mocks


shared_examples_for 'a receiving component, integration level' do |input_queues|

  describe 'common receiving behavior' do
    it_should_behave_like 'a messaging component, integration level', input_queues
  end


  describe 'unique receiving behavior' do

    let(:mock_queue) { create_mock_queue }

    describe 'initial setup' do

      input_queues.each do |queue_name|

        it "should be listening to its queue (#{queue_name})" do
          # configuration and clazz must be defined externally
          configuration[queue_name.to_sym] = mock_queue
          component = clazz.new(configuration)

          begin
            component.start

            expect(mock_queue).to have_received(:subscribe_with)
          ensure
            component.stop
          end
        end

      end

    end

  end
end
