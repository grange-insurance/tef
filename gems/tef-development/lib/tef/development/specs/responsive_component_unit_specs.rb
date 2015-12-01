shared_examples_for 'a responsive component, unit level' do |queue_param_names|

  describe 'common responsive behavior' do
    it_should_behave_like 'a receiving component, unit level', queue_param_names
  end

end
