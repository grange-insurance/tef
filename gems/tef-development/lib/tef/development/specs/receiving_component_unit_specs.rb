require_relative 'messaging_component_unit_specs'


shared_examples_for 'a receiving component, unit level' do |clazz, configuration, input_queues|

  it_should_behave_like 'a messaging component, unit level', input_queues do
    let(:clazz) { clazz }
    let(:configuration) { configuration }
  end

end
