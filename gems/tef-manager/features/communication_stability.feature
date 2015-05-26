Feature: Communication stability

  Managers are likely to be long running applications since they are the primary control component of
  the entire TEF framework. It is likely that situations will arise when their message service becomes
  temporarily unavailable (e.g. looses connection, restarts, etc.). In these cases, it is important
  that a manager can smoothly reconnect and resume its previous work without loss of message data.

  Scenario: Message queues persist through message service loss
    Given a manager is started
    And manager message queues are available
    When the message service goes down
    And the message service comes up
    Then the message queues are still available
    And the manager can still receive and send messages through them


  @wip
  Scenario: Outgoing messages persist through message service loss

  @wip
  Scenario: Incoming messages persist through worker loss
