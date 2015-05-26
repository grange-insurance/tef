# Hive NG

Hive 1 was implemented using SOA with the intent of being able to replace large chunks of it without disturbing the rest.

Assumptions were made during it's development that haven't always proven out.  For example the priority level system isn't particularly useful while the resource system is critical.  The priority system really only mediates competition for resources not workers.

Some things weren't well thought out at all like the environment + suite nonsense.


### What to change

Hive 1 is hard wired to run cucumber and in a very specific way.  This requires eveything to look like SEQ in order to fit in.  This was always meant to be temporary but we've already had a case where it was more expedient to shoe-horn a project in then devote the time to do it right...

The desired worker is something similar to how Resque does things.  A task is a serialzed Ruby object that implements an interface. An additional interface for storing results/metadata allows teams a clear path for integration.


#### Workers
* Dump DrB allow Rabbit to deliver tasks and results.
* New task object model.



#### Queuebert

* Serialize suite w/tasks via Rabbit instead of DB.
* Replace web API with Rabbit RPC?

#### Manager
* Pulls from Queueberts queue.  
* Replace web API with Rabbit RPC.
* Requeues things it doesn't have resources for.
* Three prirority levels (seperate queues).
* Only accepts from queue when workers are available. (Possible to use subscriber count - unacked tasks?)
* Pssoible to only ack input queue once worker acks?

#### Keeper
* Tasks must expose a keeper interface to store their own results / metadata.
* Create basic metadata gem for storing extra info during tests.  Allow screenshot grabbing for arbitratry pages + points in time.
* Replace unit formatter with json.

#### Hunnypot
* Caching  