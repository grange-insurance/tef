require_relative 'messaging_component_unit_specs'


shared_examples_for 'a sending component, integration level' do |output_queues|

  describe 'common sending behavior' do
    it_should_behave_like 'a messaging component, integration level', output_queues
  end

end
