shared_examples_for 'a rooted component, unit level' do

  before(:each) do
    @options = configuration.dup
    @component = clazz.new(@options)
  end

  it 'has a root location' do
    expect(@component).to respond_to(:root_location)
  end

  it 'can be provided with a root location when created' do
    @options[:root_location] = 'some root location'
    component = clazz.new(@options)

    expect(component.root_location).to eq('some root location')
  end

end
