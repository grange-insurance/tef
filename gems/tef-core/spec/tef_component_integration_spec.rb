require 'spec_helper'
require 'tef/core/tef_component'


describe 'TefComponent, Integration' do

  let(:clazz) { TEF::Core::TefComponent }
  let(:configuration) { {} }


  it_should_behave_like 'a logged component, integration level'
  it_should_behave_like 'a service component, integration level'

end
