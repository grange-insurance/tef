Feature: Handling a task result

  A keeper receives task results to deal with in some way. How a task result is dealt with is entirely user
  defined.


  Scenario: Task result is processed
    Given a keeper is started
    When it is given a task result to handle
    Then the result is handled

  Scenario: Task result is passed along to the next TEF component
    Given a keeper is started
    When it is given a task result to handle
    Then the result is forwarded and routed with "task"

