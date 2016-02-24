Feature: End to end acceptance testing

  Everything should work!


  Background: Clean workspace
    * no TEF nodes are running

  Scenario: Basic task handling
    And a local manager node is running
    And local worker nodes are running
    And a keeper node is running
    When tasks are sent to the manager
    Then the result for the executed tasks are handled by the keeper
