require_relative '../testing/mocks'
include TEF::Development::Testing::Mocks


shared_examples_for 'a logged component, unit level' do

  before(:each) do
    @mock_logger = create_mock_logger

    @options = configuration.dup
    @component = clazz.new(@options)
  end


  it 'has a logging object' do
    expect(@component).to respond_to(:logger)
  end

  it 'delegates logging to its provided logger' do
    @options[:logger] = @mock_logger

    component = clazz.new(@options)

    expect(component.logger).to eq(@mock_logger)
  end

end
