Feature: End to end acceptance testing

  Everything should work!


  Background: Clean workspace
    * no TEF nodes are running

  Scenario: Basic task handling
    And a local configured manager node is running
    And local configured worker nodes are running
    And a local configured keeper node is running
    And all components have finished starting up
    When tasks are sent to the manager
    Then the result for the executed tasks are handled by the keeper
