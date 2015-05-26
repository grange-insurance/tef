shared_examples_for 'a rooted component, integration level' do

  before(:each) do
    @options = configuration.dup
  end


  it 'root location defaults to an environmental variable if not provided at creation' do
    env_var = 'TEF_WORK_NODE_ROOT_LOCATION'
    old_env = ENV[env_var]

    begin
      ENV[env_var] = 'some root location'
      @options.delete(:root_location)

      component = clazz.new(@options)

      expect(component.root_location).to eq('some root location')
    ensure
      ENV[env_var] = old_env
    end

  end

end
