require 'spec_helper'
require 'tef/core/inner_component'


describe 'InnerComponent, Integration' do

  let(:clazz) { TEF::Core::InnerComponent }
  let(:configuration) { {in_queue: create_mock_queue} }

  it_should_behave_like 'a logged component, integration level'

end
