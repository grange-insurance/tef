require_relative 'messaging_component_unit_specs'


shared_examples_for 'a sending component, integration level' do |clazz, configuration, output_queues|

  it_should_behave_like 'a messaging component, integration level', output_queues do
    let(:clazz) { clazz }
    let(:configuration) { configuration }
  end

end
