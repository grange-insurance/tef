require 'socket'

Then(/^the following message queues have been created:$/) do |queue_names|
  queue_names = queue_names.raw.flatten.map { |name| name.sub('<env>', @tef_env).sub('<name>', Socket.gethostname).sub('<pid>', Process.pid.to_s).sub('<worker_type>', @worker_type).sub('<keeper_type>', @keeper_type) }

  queue_names.each do |queue_name|
    raise("Expected queue '#{queue_name}' to exist but it did not.") unless @bunny_connection.queue_exists?(queue_name)
  end
end

Then(/^the following message exchanges have been created:$/) do |exchange_names|
  exchange_names = exchange_names.raw.flatten.map { |name| name.sub('<env>', @tef_env) }

  exchange_names.each do |exchange_name|
    raise("Expected exchange '#{exchange_name}' to exist but it did not.") unless @bunny_connection.exchange_exists?(exchange_name)
  end
end

Then(/^the message queues are still available$/) do
  @expected_queues.each do |queue_name|
    expect(@bunny_connection.queue_exists?(queue_name)).to be true
  end
end

Then(/^the message exchanges are still available$/) do
  @expected_exchanges.each do |exchange_name|
    expect(@bunny_connection.exchange_exists?(exchange_name)).to be true
  end
end
