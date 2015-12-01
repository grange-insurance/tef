require_relative 'messaging_component_unit_specs'


shared_examples_for 'a receiving component, unit level' do |input_queues|

  describe 'common receiving behavior' do
    it_should_behave_like 'a messaging component, unit level', input_queues
  end

end
