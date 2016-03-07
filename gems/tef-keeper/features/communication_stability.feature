Feature: Communication stability

  Due to being the endpoint of many different worked tasks, keepers are likely to be long running
  applications. It is likely that situations will arise where their message service becomes temporarily
  unavailable (e.g. looses connection, restarts, etc.). In these cases, it is important that a keeper
  can smoothly reconnect and resume its previous work without loss of message data.


  Scenario: Message endpoints persist through message service loss

  Note: the keeper will need to requeue a task in order to make sure that all of its queues still work

    Given a keeper is started
    And the keeper message queues are available
    And the keeper message exchanges are available
    When the message service goes down
    And the message service comes up
    Then the message queues are still available
    And the message exchanges are still available
    And the keeper can still receive and send messages through them


  @wip
  Scenario: Outgoing messages persist through message service loss

  @wip
  Scenario: Incoming messages persist through keeper loss
