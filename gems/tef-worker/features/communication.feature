Feature: Communication

  Workers use a messaging service to communicate with other components of the TEF.


  Scenario: Creates endpoints on startup
    Given message queues for the Worker have not yet been created
    And message exchanges for the Worker have not yet been created
    When a worker is started
    Then message queues for the Worker have been created
    And message exchanges for the Worker have been created

  Scenario: Default endpoint names

  Note: The default endpoint names incorporate the current environment (e.g. dev/test/prod)
  and the machine name and process id of the worker, as well as the type of the worker.

    Given the following message queues have not been yet been created:
      | tef.<env>.worker.<name>.<pid> |
      | tef.<env>.manager             |
    And the following message exchanges have not been yet been created:
      | tef.<env>.<worker_type>.worker_generated_messages |
    When a worker is started
    Then the following message queues have been created:
      | tef.<env>.worker.<name>.<pid> |
      | tef.<env>.manager             |
    And the following message exchanges have been created:
      | tef.<env>.<worker_type>.worker_generated_messages |

  Scenario: Custom prefix
    Given the following message queues have not been yet been created:
      | my_custom.prefix.worker.<name>.<pid>  |
      | my_custom.prefix.manager             |
    And the following message exchanges have not been yet been created:
      | my_custom.prefix.<worker_type>.worker_generated_messages |
    And a name prefix of "my_custom.prefix"
    When a worker is started
    Then the following message queues have been created:
      | my_custom.prefix.worker.<name>.<pid>  |
      | my_custom.prefix.manager             |
    And the following message exchanges have been created:
      | my_custom.prefix.<worker_type>.worker_generated_messages |

  Scenario: Custom queue names
    Given the following message queues have not been yet been created:
      | special.worker.queue  |
      | special.manager.queue |
    And the following message exchanges have not been yet been created:
      | special.worker.exchange |
    And a worker queue name of "special.worker.queue"
    And an output exchange name of "special.worker.exchange"
    And a manager queue name of "special.manager.queue"
    When a worker is started
    Then the following message queues have been created:
      | special.worker.queue  |
      | special.manager.queue |
    And the following message exchanges have been created:
      | special.worker.exchange |
