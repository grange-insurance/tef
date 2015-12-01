shared_examples_for 'a service component, unit level' do

  # 'clazz' must be defined by an including scope
  # 'configuration' must be defined by an including scope

  let(:component) { clazz.new(configuration) }


  it 'can be started' do
    expect(component).to respond_to(:start)
  end

  it 'can be stopped' do
    expect(component).to respond_to(:stop)
  end

end
