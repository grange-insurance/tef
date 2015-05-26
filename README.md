# *The Hive* a task execution framework 
#

## About
tldr; The Hive is a distributed processing grid that's aware of available resources. 

The Hive was developed to support large scale automated-testing at Grange Insurance.  Comprised of several micro-services that communicate over [RabbitMQ](http://www.rabbitmq.com/), the Hive is designed to be easily extensible and maintainable. It the latest a series of grids built to support the ever-growing automation efforts at Grange.

Grange bought into both Agile and automated testing in a big way several years ago. The *Grange Grid* was built to support testing on Windows using *Internet Explorer*. The architecture has evolved over the years with the following guiding principles:

- **Nothing gets lost** - If something goes wrong (and it will) it should leave a trace.
- **Shorten the feedback loop** - The sooner you know something it broken the cheaper and easier it is to fix.
- **Noise should not be tolerated** - Purely environmental issues shouldn't be allowed to impact results.
- **Maximize resources** - Send exactly as many workers at any one server as they can handle.  Too few lengthens the feedback loop, too many introduces errors.


## Services
The services below make up a typical Hive installation.

 - **Manager** - Acts as a traffic cop, directing tasks to workers.  It accepts new tasks in JSON format via an "input" RabbitMQ exchange.  Workers, and others, can communicate with the Manager via the "control" RabbitMQ exchange.
 - **Worker** - Executes tasks. Each type of task requires a worker that can handle it, at a minimum. The only requirement placed on a worker by the Hive is that it be cable of receiving a task in JSON via RabbitMQ and that it advertise it's availability to the manger via RabbitMQ.
 - **Keeper** - Receives the output of the workers.  In most cases a custom keeper is developer for each custom task.  A simple implementation of a Keeper for a task could store the results in a database.  However if the Keeper implements a rule engine capable of triaging results, environmental noise can be reduced by requeueing tasks.
 - **Queuebert** - Generates tasks and sends them off to the Manager via it's "input" exchange. For example:  The Cucumber Queuebert is capable of breaking down feature files into smaller units of work before sending them off to be executed on Hive workers.       



Queuebert
=========

Queuebert is responsible for dynamically creating the tasks that are sent to the Hive Manager.




