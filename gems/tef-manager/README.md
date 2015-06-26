TEF Manager
=========

The TEF Manager is responsible for dispatching tasks to the workers. The manager distributes tasks to workers based on the availability of the resources needed by a task and the availability of workers of a type corresponding to the type of the task.


Getting Started
=========

To run the manager service on a machine:

* Set the environmental variables that the manager will use to configure itself (see below)
* Install the manager gem
 ```
 gem install tef-manager
 ```
* Run the provided service binary
 ```
 start_tef_manager
 ```
* Start sending tasks to the manager via RabbitMQ


Important Environment Variables
=========
 * **TEF_ENV** - Determines the environment you're running in.  This should be one of: dev, test or prod.  It defaults to dev.
 * **TEF_AMQP_URL_(TEF_ENV value)** - The URL that maps to the RabbmitMQ instance that the manager will use to communicate with other parts of the TEF (e.g. "amqp://guest:guest@localhost:5672"). 
 * **TEF_CONFIG** - The path to the folder containing the database configuration files for the manager.
 * **TEF_ETCD_HOST_(TEF_ENV value)** - The host that is running the Etcd instance that the manager will use to track resource usage (e.g. "127.0.0.1"). 
 * **TEF_ETCD_PORT_(TEF_ENV value)** - The port number used by the Etcd instance (e.g. "4001"). 


A Manager's view of a task
=========

The manager only pays attention to the parts of a task needed to route the task to an appropriate worker.
 
In the example task below, that would mean that the manager utilizes every field except for **task_data**.

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

Dispatcher Control Messages
========= 
Dispatcher control messages have a type and data at a minimum.  Below is an example command to set the state of the manager.
 ```json
 {
   "type": "set_state",
   "data": "paused"
 }
 ```

Valid message types are:

* **set_state** - Data should be one of: running | paused | stopped


WorkerCollective Control Messages
========= 
Like the dispatcher, the WorkerCollective accepts control messages 
 
Valid message types are:

**worker_status** - Updates the status of a worker.  If the worker does not yet exist in the collective, it will be added.  Workers should send this periodically

Status can be one of the following:

 * **ready** - The worker is up and available for work.
 * **offline** - The worker should be considered offline and removed from the collective.
 * **working** - The worker is up but busy working on a task.  The "task" field should be present and populated with the guid of the task being worked. 

 ```json
 {
   "type": "worker_status",
   "name": "worker_foo",
   "worker_type": "type_1",
   "exchange_name": "tef.dev.workers.worker_foo",
   "status": "<status string>",
   "task:" "<optional guid of a task>"
 }
 ```

**get_workers** - Gets the list of workers with their status.  You must set reply_to and the correlation_id when making this request.
```json
{
 "type": "get_workers"
}
   ``` 
