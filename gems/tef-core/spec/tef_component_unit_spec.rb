require 'spec_helper'
require 'tef/core/tef_component'


describe 'TefComponent, Unit' do

  clazz = TEF::Core::TefComponent


  it_should_behave_like 'a configured component', clazz

  it_should_behave_like 'a service component, unit level' do
    let(:clazz) { clazz }
    let(:configuration) { {} }
  end

  it_should_behave_like 'a logged component, unit level' do
    let(:clazz) { clazz }
    let(:configuration) { {} }
  end

end
