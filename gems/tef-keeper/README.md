TEF Keeper
=========

A Keeper is responsible handling the results of tasks. The exact manner in which a result is handled is entirely user defined but common actions include storing the task output in a database or logging some kind of success/failure status.


Getting Started
=========

To run the keeper service on a machine:

* Set the environmental variables that the keeper will use to configure itself (see below)
* Install the keeper gem
 ```
 gem install tef-keeper
 ```
* Unlike other service gems, there is no provided binary to run because the behavior of handling a task must be provided by the user. Below is an example Ruby script that will run a Keeper service that simply outputs the id of the tasks that it handles:

```ruby
require 'tef/keeper'


options = {}
options[:keeper_type] = 'generic'
options[:callback] = lambda { |delivery_info, properties, payload, logger|
  logger.info("Received a #{payload[:type]} message")
  logger.info("GUID is #{payload[:guid]}")
}

keeper_node = TEF::Keeper::Keeper.new(options)
keeper_node.start

# Run the service until its process is ended
begin
  loop do
    sleep 1
  end
rescue Interrupt => _
  keeper_node.stop

  exit(0)
end
```

* Wait for the keeper to start receiving tasks from workers


Important Environment Variables
=========
 * **TEF_ENV** - Determines the environment you're running in.  This should be one of: dev, test or prod.  It defaults to dev.
 * **TEF_AMQP_URL_(TEF_ENV value)** - The URL that maps to the RabbmitMQ instance that the keeper will use to communicate with other parts of the TEF (e.g. "amqp://guest:guest@localhost:5672"). 


A Keeper's view of a task
=========

How a keeper handles a task is user defined. However, a keeper only receives tasks that it knows how to handle. What kind of tasks a keeper can handle is identified by its type.

Below is a hypothetical 'echo' task. Since the **task_type** is 'echo', the keeper that handles it should also be configured as an 'echo' keeper.

```json
{
  "type": "task",
  "task_type": "echo",
  "guid": "task_123456",
  "priority": 5,
  "resources": ["resource_1","resource_2","resource_3"],
  "time_limit": 600,
  "task_data": {"message": "hello world",
                "output": "success"},
  "suite_guid": "task_suite_7"  
}
```
