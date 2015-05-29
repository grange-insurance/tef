@wip
Feature: Result saving

  Keeper handles saving the results of a task for future use. Due to the varied nature of tasks and how
  their results should be retained, the specific process of handling a result is up to the user to define.


  Background:
    Given a queue to receive from
    And something with which to save results


  Scenario: Received results are processed
    Given the following result processing block:
      """
      { | delivery_info, properties, message |
        message = JSON.parse(message)

        TEF::Keeper::TaskResult.create(property_1: message['property_1'],
                                        property_3: message['property_3'])
      }
      """
    When the following task result has been received:
      """
      {
        "property_1": "1",
        "property_2": "2",
        "property_3": "3"
      }
      """
    Then the following data is stored for the result:
      | property_1 | 1 |
      | property_3 | 3 |

  Scenario: No defined process
    Given no result processing block has been defined
    When the following task result has been received:
    """
      {
        "property_1": "1",
        "property_2": "2",
        "property_3": "3"
      }
      """
    Then no data is stored for the result
