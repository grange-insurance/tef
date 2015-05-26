TEF Manager
=========

The TEF Manager is responsible for dispatching tasks to the workers.


Important Environment Variables
=========
 * **TEF_ENV** - Determines the environment you're running in.  This should be one of: dev, test or prod.  It defaults to dev
 * **TEF_CONFIG** - The path to the folder containing the config files for the tef.
 * **TEF_AMQP_URL** - The URL that maps to a RabbmitMQ instance e.g. "amqp://guest:guest@localhost:5672" 



Anatomy of a Task
=========

TEF tasks are shuffled around in a JSON envelope.  The envelope contains just enough information to route the task. The **task_data** field contains the meat of the task, but the Manager does not touch this field.

The properties of a task are as follows:

 * **type**          - A string identifying the type of of message, for tasks this is "task" 
 * **task_type**     - A string identifying the type of task this is.
 * **guid**          - A GUID that uniquely identifies this task  
 * **priority**      - A numeric value indicating how important a task is.  Higher numbers are better.
 * **resources**     - A pipe delimited list of resource names this task depends on.
 * **time_limit**    - How long can this task be in the "working" state before being considered stalled and getting redispatched.
 * **task_data**     - An arbitrary blob of data to be consumed by the task specific workers and keepers.
 * **suite_guid**    - A GUID that can be used to group tasks into a group.


Below is an example task envelope for a hypothetical "echo" task.
```json
{
  "type": "task",
  "task_type": "echo",
  "guid": "a_guid",
  "priority": 5,
  "resources": "pipe|delimited|list",
  "time_limit": number_of_seconds,
  "task_data": "ew0KICAibWVzc2FnZSI6ICJIZWxsbyBXb3JsZCINCn0=",
  "suite_guid": "a_guid"  
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


**remove_worker** - Removes a worker from the collective
 ```json
 {
   "type": "remove_worker",
   "name": "worker_foo"
 }
 ```
  
**get_workers** - Gets the list of workers with their status.  You must set reply_to and the correlation_id when making this request.
```json
{
 "type": "get_workers"
}
   ``` 

 
