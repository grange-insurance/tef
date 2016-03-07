require 'spec_helper'
require 'tef/core/outer_component'


describe 'OuterComponent, Unit' do

  let(:clazz) { TEF::Core::OuterComponent }
  let(:configuration) { {} }


  it_should_behave_like 'a configured component'
  it_should_behave_like 'a service component, unit level'
  it_should_behave_like 'a logged component, unit level'
  it_should_behave_like 'a wrapper component, unit level', [:in_queue, :output_exchange]

end
