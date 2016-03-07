require 'spec_helper'
require 'tef/core/outer_component'


describe 'OuterComponent, Integration' do

  let(:clazz) { TEF::Core::OuterComponent }
  let(:configuration) { {} }


  it_should_behave_like 'a logged component, integration level'
  it_should_behave_like 'a service component, integration level'
  it_should_behave_like 'a wrapper component, integration level', [:in_queue, :output_exchange]

end
