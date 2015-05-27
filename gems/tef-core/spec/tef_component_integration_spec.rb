require 'spec_helper'

describe 'TefComponent, Integration' do

  clazz = TEF::TefComponent


  it_should_behave_like 'a logged component, integration level' do
    let(:clazz) { clazz }
    let(:configuration) { {} }
  end

  it_should_behave_like 'a service component, integration level' do
    let(:clazz) { clazz }
    let(:configuration) { {} }
  end

end
