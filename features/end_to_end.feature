#todo - have to rewrite this to not be a tef-cucumber based use case
@wip
Feature: End to end acceptance testing

  Everything should work!


  Background: Clean workspace
    * no TEF nodes are running

  Scenario: Cucumber task
    Given a queuebert node is running
    And a manager node is running
    And a cuke worker node is running
    And a cuke keeper node is running
    When  a request for a test suite is sent
    Then results for the executed tests are stored by the keeper
