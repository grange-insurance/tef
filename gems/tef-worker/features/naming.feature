Feature: Naming

  Workers have flexible names.


  Scenario: Default worker name

  Note: The default worker name incorporate the machine name and process id of the worker.

    Given a worker is created
    Then the worker name is "<machine_name>.<pid>"

  Scenario: Custom worker name
    Given a worker name of "special_worker_name"
    Given a worker is created
    Then the worker name is "special_worker_name"
