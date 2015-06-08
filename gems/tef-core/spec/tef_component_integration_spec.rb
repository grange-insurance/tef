require 'spec_helper'
require 'tef/core/tef_component'


describe 'TefComponent, Integration' do

  clazz = TEF::Core::TefComponent


  it_should_behave_like 'a logged component, integration level' do
    let(:clazz) { clazz }
    let(:configuration) { {} }
  end

  it_should_behave_like 'a service component, integration level' do
    let(:clazz) { clazz }
    let(:configuration) { {} }
  end

end
