shared_examples_for 'a rooted component, unit level' do

  # 'clazz' must be defined by an including scope
  # 'configuration' must be defined by an including scope

  let(:component) { clazz.new(configuration) }


  it 'has a root location' do
    expect(component).to respond_to(:root_location)
  end

  it 'can be provided with a root location when created' do
    configuration[:root_location] = 'some root location'
    component = clazz.new(configuration)

    expect(component.root_location).to eq('some root location')
  end

end
