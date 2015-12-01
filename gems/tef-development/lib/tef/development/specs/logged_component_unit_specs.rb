require_relative '../testing/mocks'
include TEF::Development::Testing::Mocks


shared_examples_for 'a logged component, unit level' do

  # 'clazz' must be defined by an including scope
  # 'configuration' must be defined by an including scope

  let(:mock_logger) { create_mock_logger }
  let(:component) { clazz.new(configuration) }


  it 'has a logging object' do
    expect(component).to respond_to(:logger)
  end

  it 'delegates logging to its provided logger' do
    configuration[:logger] = mock_logger

    component = clazz.new(configuration)

    expect(component.logger).to eq(mock_logger)
  end

end
