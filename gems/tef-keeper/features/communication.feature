Feature: Communication

  Keepers use a messaging service to communicate with other components of the TEF.


  Scenario: Creates endpoints on startup
    Given message queues for the keeper have not yet been created
    And message exchanges for the keeper have not yet been created
    When a keeper is started
    Then message queues for the keeper have been created
    And message exchanges for the keeper have been created

  Scenario: Default endpoint names

  Note: The default endpoint names incorporate the current environment (e.g. dev/test/prod)
  and name of the keeper.

    Given the following message queues have not been yet been created:
      | tef.<env>.keeper.<keeper_type> |
    And the following message exchanges have not been yet been created:
      | tef.<env>.<keeper_type>.keeper_generated_messages |
    When a keeper is started
    Then the following message queues have been created:
      | tef.<env>.keeper.<keeper_type> |
    And the following message exchanges have been created:
      | tef.<env>.<keeper_type>.keeper_generated_messages |

  Scenario: Custom prefix
    Given the following message queues have not been yet been created:
      | my_custom.prefix.keeper.<keeper_type> |
    And the following message exchanges have not been yet been created:
      | my_custom.prefix.<keeper_type>.keeper_generated_messages |
    And a name prefix of "my_custom.prefix"
    When a keeper is started
    Then the following message queues have been created:
      | my_custom.prefix.keeper.<keeper_type> |
    And the following message exchanges have been created:
      | my_custom.prefix.<keeper_type>.keeper_generated_messages |

  Scenario: Custom queue names
    Given the following message queues have not been yet been created:
      | special.keeper.queue |
    And the following message exchanges have not been yet been created:
      | special.keeper.exchange |
    And a keeper queue name of "special.keeper.queue"
    And an output exchange name of "special.keeper.exchange"
    When a keeper is started
    Then the following message queues have been created:
      | special.keeper.queue |
    And the following message exchanges have been created:
      | special.keeper.exchange |
