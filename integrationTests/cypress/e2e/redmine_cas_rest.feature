Feature: Redmine CAS plugin rest API functionality

  Scenario: user can authenticate via basic authentication with valid credentials
    Given the user has valid login credentials
    When the user authenticate via basic authentication
    Then the user receives a json response with valid cas attributes

  Scenario: user cannot authenticate via basic authentication with invalid credentials
    Given the user has invalid login credentials
    When the user authenticate via basic authentication
    Then the user receives a 401 response

  Scenario: user can authenticate with valid api key
    Given the user has valid login credentials
    And the user has a valid api key
    When the user authenticate via api key
    Then the user receives a json response with valid cas attributes

  Scenario: user cannot authenticate with invalid api key
    Given the user has an invalid api key
    When the user authenticate via api key
    Then the user receives a 401 response