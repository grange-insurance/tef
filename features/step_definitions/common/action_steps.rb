When(/^the message service goes down$/) do
  # This probably needs tweaked to work when not in 'dev' mode
  success = system('rabbitmqctl stop_app')
  raise("Could not successfully shut down the message service") unless success
end

And(/^the message service comes up$/) do
  # This probably needs tweaked to work when not in 'dev' mode
  success = system('rabbitmqctl start_app')
  raise("Could not successfully restart the message service") unless success

  @bunny_connection = Bunny.new(@bunny_url)
  @bunny_connection.start
  @bunny_channel = @bunny_connection.create_channel
end

