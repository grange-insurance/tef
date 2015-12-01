require_relative 'messaging_component_unit_specs'


shared_examples_for 'a sending component, unit level' do |output_queues|

  describe 'common sending behavior' do
    it_should_behave_like 'a messaging component, unit level', output_queues
  end

end
