Feature: Administrative Procedures via API

  @requires_testuser
  Scenario: a CAS user which is member to the admin user-group can access the users api endpoint
    Given the user is member of the admin user group
    And the user has an internal default redmine account
    When the user request the user.json from Redmine via API key
    Then the user receives the user.json as response

  @requires_testuser
  Scenario: a CAS user which is not member to the admin user-group cannot access the users api endpoint
    Given the user is not member of the admin user group
    And the user has an internal default redmine account
    When the user request the user.json from Redmine via API key
    Then the user receives an unauthorized access response

  @requires_testuser
  Scenario: a regular CAS user with an internal redmine admin account can access the users api endpoint
    Given the user is not member of the admin user group
    And the user has an internal redmine account with admin privileges granted by another admin
    When the user request the user.json from Redmine via API key
    Then the user receives the user.json as response

  @requires_testuser
  Scenario: a regular cas user gets his internal redmine admin rights revoked and can afterwards not access the users API endpoint anymore
    Given the user is not member of the admin user group
    And the user has an internal redmine account with admin privileges granted by another admin
    When the admin removes the admin privileges from the user via redmine
    And the user request the user.json from Redmine via API key
    Then the user receives an unauthorized access response

  @requires_testuser
  Scenario: a user with prior redmine admin privileges gets demoted and afterwards is assigned to the admin user-group and can therefore access the users api endpoint successfully
    Given the user is not member of the admin user group
    And the user has an internal redmine account with admin privileges granted by another admin
    When the admin removes the admin privileges from the user via redmine
    And the user is added as a member to the ces admin group
    And the user logs into the CES
    And the user request the user.json from Redmine via API key
    Then the user receives the user.json as response