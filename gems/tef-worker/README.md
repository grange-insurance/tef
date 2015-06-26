TEF Worker
=========

A Worker is responsible for performing the tasks dispatched to it by a Manager.


Getting Started
=========

To run the worker service on a machine:

* Set the environmental variables that the worker will use to configure itself (see below)
* Install the worker gem
 ```
 gem install tef-worker
 ```
* Run the provided service binary
 ```
 start_tef_worker
 ```
* Wait for the worker to start receiving tasks from a manager


Important Environment Variables
=========
 * **TEF_ENV** - Determines the environment you're running in.  This should be one of: dev, test or prod.  It defaults to dev.
 * **TEF_AMQP_URL_(TEF_ENV value)** - The URL that maps to the RabbmitMQ instance that the worker will use to communicate with other parts of the TEF (e.g. "amqp://guest:guest@localhost:5672"). 
 * **TEF_WORK_NODE_ROOT_LOCATION** - The file path from which the worker will derive all file paths needed to do its work.


A Worker's view of a task
=========

Since a worker can assume that it will only receive tasks that have been correctly routed to it, it ignores most parts of a task message and works primarily on the contained **task data**.
 
Since the information contained in **task_data** depends entirely on what the type of task is, its form will vary. In the hypothetical example task below, the data contains the message that will be echoed to the console when the task is executed.

```json
{
  "type": "task",
  "task_type": "echo",
  "guid": "task_123456",
  "priority": 5,
  "resources": "pipe|delimited|list",
  "time_limit": 600,
  "task_data": {"message": "hello world"},
  "suite_guid": "task_suite_7"  
}
```
