Feature: Communication

  A manager uses a messaging service to communicate with other components of the TEF.


  Scenario: Creates queues on startup
    Given message in/out queues for the manager have not been yet been created
    When a manager is started
    Then message in/out queues for the manager have been created

  Scenario: Default queue names

  Note: The default queue names incorporate the current environment (e.g. dev/test/prod)
  and the machine name and process id of the worker.

    Given the following message queues have not been yet been created:
      | tef.<env>.task_queue.control |
      | tef.<env>.dispatcher.control |
      | tef.<env>.worker.control     |
    When a manager is started
    Then the following message queues have been created:
      | tef.<env>.task_queue.control |
      | tef.<env>.dispatcher.control |
      | tef.<env>.worker.control     |

  Scenario: Custom prefix
    Given the following message queues have not been yet been created:
      | my_custom.prefix.task_queue.control |
      | my_custom.prefix.dispatcher.control |
      | my_custom.prefix.worker.control     |
    And a name prefix of "my_custom.prefix"
    When a manager is started
    Then the following message queues have been created:
      | my_custom.prefix.task_queue.control |
      | my_custom.prefix.dispatcher.control |
      | my_custom.prefix.worker.control     |

  Scenario: Custom queue names
    Given the following message queues have not been yet been created:
      | special.task_queue.queue |
      | special.dispatcher.queue |
      | special.worker.queue     |
    And a task queue queue name of "special.task_queue.queue"
    And a dispatcher queue name of "special.dispatcher.queue"
    And a worker queue name of "special.worker.queue"
    When a manager is started
    Then the following message queues have been created:
      | special.task_queue.queue |
      | special.dispatcher.queue |
      | special.worker.queue     |
