Feature: Communication stability

  Workers are likely to be long running applications, either do to working lengthy tasks or being kept
  around to work many tasks over their lifetime. It is likely that situations will arise their message
  service becomes temporarily unavailable (e.g. looses connection, restarts, etc.). In these cases, it
  is important that a worker can smoothly reconnect and resume its previous work without loss of
  message data.

  Scenario: Message endpoints persist through message service loss
    Given a worker is started
    And worker message queues are available
    And worker message exchanges are available
    When the message service goes down
    And the message service comes up
    Then the message queues are still available
    Then the message exchanges are still available
    And the worker can still receive and send messages through them


  @wip
  Scenario: Outgoing messages persist through message service loss

  @wip
  Scenario: Incoming messages persist through worker loss
