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
      | tef.<env>.manager |
    When a manager is started
    Then the following message queues have been created:
      | tef.<env>.manager |

  Scenario: Custom prefix
    Given the following message queues have not been yet been created:
      | my_custom.prefix.manager |
    And a name prefix of "my_custom.prefix"
    When a manager is started
    Then the following message queues have been created:
      | my_custom.prefix.manager |

  Scenario: Custom queue names
    Given the following message queues have not been yet been created:
      | special.manager_queue |
    And a manager queue queue name of "special.manager_queue"
    When a manager is started
    Then the following message queues have been created:
      | special.manager_queue |
