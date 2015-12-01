require 'spec_helper'
require 'tef/core/tef_component'


describe 'TefComponent, Unit' do

  let(:clazz) { TEF::Core::TefComponent }
  let(:configuration) { {} }


  it_should_behave_like 'a configured component'
  it_should_behave_like 'a service component, unit level'
  it_should_behave_like 'a logged component, unit level'

end
