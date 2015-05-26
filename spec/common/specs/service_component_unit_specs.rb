require_relative '../../../testing/mocks'
include TefTestingMocks

shared_examples_for 'a service component, unit level' do

  before(:each) do
    @mock_logger = create_mock_logger

    @options = configuration.dup
    @component = clazz.new(@options)
  end


  it 'can be started' do
    expect(@component).to respond_to(:start)
  end

  it 'can be stopped' do
    expect(@component).to respond_to(:stop)
  end

end
