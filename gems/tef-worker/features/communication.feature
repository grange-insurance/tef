Feature: Communication

  Workers use a messaging service to communicate with other components of the TEF.


  Scenario: Creates queues on startup
    Given message in/out queues for the Worker have not been yet been created
    When a worker is started
    Then message in/out queues for the Worker have been created

  Scenario: Default queue names

  Note: The default queue names incorporate the current environment (e.g. dev/test/prod)
  and the machine name and process id of the worker.

    Given the following message queues have not been yet been created:
      | tef.<env>.worker.<name>.<pid>  |
      | tef.<env>.keeper.<worker_type> |
      | tef.<env>.manager              |
    When a worker is started
    Then the following message queues have been created:
      | tef.<env>.worker.<name>.<pid>  |
      | tef.<env>.keeper.<worker_type> |
      | tef.<env>.manager              |

  Scenario: Custom prefix
    Given the following message queues have not been yet been created:
      | my_custom.prefix.worker.<name>.<pid>  |
      | my_custom.prefix.keeper.<worker_type> |
      | my_custom.prefix.manager              |
    And a name prefix of "my_custom.prefix"
    When a worker is started
    Then the following message queues have been created:
      | my_custom.prefix.worker.<name>.<pid>  |
      | my_custom.prefix.keeper.<worker_type> |
      | my_custom.prefix.manager              |

  Scenario: Custom queue names
    Given the following message queues have not been yet been created:
      | special.worker.queue  |
      | special.keeper.queue  |
      | special.manager.queue |
    And a worker queue name of "special.worker.queue"
    And a keeper queue name of "special.keeper.queue"
    And a manager queue name of "special.manager.queue"
    When a worker is started
    Then the following message queues have been created:
      | special.worker.queue  |
      | special.keeper.queue  |
      | special.manager.queue |
