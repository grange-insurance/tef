Feature: Working a task

  A worker receives tasks to work. It sends the results of these tasks along to a keeper for storage.

  Scenario: Working a task
    Given a worker is started
    When it is given a task to work
    Then the task is worked and the results are routed with "task"
