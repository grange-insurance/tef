# *The TEF* (a Task Execution Framework) 


## About
Short version: The TEF is a distributed processing grid that's aware of available resources. 

The TEF was developed to support large scale automated-testing at Grange Insurance.  Comprised of several micro-services that communicate over [RabbitMQ](http://www.rabbitmq.com/), the TEF is designed to be easily extensible and maintainable. It the latest a series of grids built to support the ever-growing automation efforts at Grange.

Grange bought into both Agile and automated testing in a big way several years ago. The *Grange Grid* was built to support testing on Windows using *Internet Explorer*. The architecture has evolved over the years with the following guiding principles:

- **Nothing gets lost** - If something goes wrong (and it will) it should leave a trace.
- **Shorten the feedback loop** - The sooner you know something it broken the cheaper and easier it is to fix.
- **Noise should not be tolerated** - Purely environmental issues shouldn't be allowed to impact results.
- **Maximize resources** - Send exactly as many workers at any one server as they can handle.  Too few lengthens the feedback loop, too many introduces errors.


## Services
The services below make up a typical TEF installation.

 - **Manager** - Acts as a traffic cop, directing tasks to workers.  Tasks can be sent to it and it will hold them until there is a worker available that can handle the task.
 - **Worker** - Executes tasks. Each type of task requires a worker that can handle it, at a minimum. The only requirement placed on a worker by the TEF is that it be cable of receiving a task in JSON via RabbitMQ and that it advertise it's availability to the manger via RabbitMQ.
 - **Keeper** - Receives the output of the workers.  In most cases a custom keeper is developed for each custom task.  A simple implementation of a Keeper for a task could store the results in a database.
  
 
## Extensibility
Additional services an be plugged into the framework in order to add more complex task processing logic or extend the types of tasks that the framework can handle. Since all services use RabbitMQ to communicate, extending the framework is as easy as creating a new service and configuring existing services to direct their input/output through the new service.
 

## Getting started

To use the Task Execution Framework, you will need instances of the following:

 - [**RabbitMQ**](https://www.rabbitmq.com/) - Used by all services to communicate with each other
 - [**ETCD**](https://github.com/coreos/etcd/releases/) - Use by the Manager to track resource availability
 - An ActiveRecord compatible database - Used by the Manager to keep track of tasks in the system
 
 The different TEF services can be run on the same machine or on separate machines with no change in their operation or configuration. For information on how to set up each service, see the documentation for each service.
 
 - [**Manager**](https://github.com/grange-insurance/tef/blob/master/gems/tef-manager/README.md)
 - [**Worker**](https://github.com/grange-insurance/tef/blob/master/gems/tef-worker/README.md)
 - [**Keeper**](https://github.com/grange-insurance/tef/blob/master/gems/tef-keeper/README.md)
 
Anatomy of a Task
=========

TEF tasks are shuffled around in a JSON envelope.  The envelope contains just enough information to route the task. The **task_data** field contains the meat of the task, including its input and output data.

The properties of a task are as follows:

 * **type**          - A string identifying the type of of message, for tasks this is "task" 
 * **task_type**     - A string identifying the type of task this is.
 * **guid**          - A GUID that uniquely identifies this task  
 * **priority**      - A numeric value indicating how important a task is (higher numbers are better). More important tasks will be dispatched to workers before less important tasks.
 * **resources**     - A list of resource names this task depends on.
 * **time_limit**    - How long (in seconds) this task can be in the "working" state before being considered stalled and getting re-dispatched to a different worker.
 * **task_data**     - An arbitrary blob of data to be consumed by the task specific workers and keepers.
 * **suite_guid**    - A GUID that can be used to group tasks into a common group.


Below is an example task envelope for a hypothetical "echo" task.
```json
{
  "type": "task",
  "task_type": "echo",
  "guid": "task_123456",
  "priority": 5,
  "resources": ["resource_1","resource_2","resource_3"],
  "time_limit": 600,
  "task_data": {command: "echo 'Hello'"},
  "suite_guid": "task_suite_7"  
}
```
