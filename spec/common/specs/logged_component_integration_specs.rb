require 'stringio'
require 'logger'

shared_examples_for 'a logged component, integration level' do

  before(:each) do
    @options = configuration.dup
  end


  it "defaults to Ruby's logging module if a logger object is not provided" do
    @options.delete(:logger)
    component = clazz.new(@options)

    expect(component.logger).to be_an_instance_of(Logger)
  end

  it 'logs to the current standard output by default' do
    old_outstream = $stdout

    begin
      new_outstream = StringIO.new
      $stdout = new_outstream

      @options.delete(:logger)
      component = clazz.new(@options)

      message = 'some log message'
      component.logger.info(message)
      output = new_outstream.string

      expect(output).to include(message)
    ensure
      $stdout = old_outstream
    end
  end

end
