Feature: Communication

  Keepers use a messaging service to communicate with other components of the TEF.


  Scenario: Creates queues on startup
    Given a keeper queue name of "some.keeper.queue"
    And an out queue name of "some.out.queue"
    And message in/out queues for the keeper have not been yet been created
    When a keeper is started
    Then message in/out queues for the keeper have been created

  Scenario: Default queue names

  Note: The default queue names incorporate the current environment (e.g. dev/test/prod)
  and name of the keeper.

    Given the following message queues have not been yet been created:
      | tef.<env>.keeper.<keeper_type> |
    When a keeper is started
    Then the following message queues have been created:
      | tef.<env>.keeper.<keeper_type> |

  Scenario: Custom prefix
    Given the following message queues have not been yet been created:
      | my_custom.prefix.keeper.<keeper_type> |
    And a name prefix of "my_custom.prefix"
    When a keeper is started
    Then the following message queues have been created:
      | my_custom.prefix.keeper.<keeper_type> |

  Scenario: Custom queue names
    Given the following message queues have not been yet been created:
      | special.keeper.queue |
      | special.out.queue    |
    And a keeper queue name of "special.keeper.queue"
    And an out queue name of "special.out.queue"
    When a keeper is started
    Then the following message queues have been created:
      | special.keeper.queue |
      | special.out.queue    |
