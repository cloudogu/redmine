Feature: Administrative Procedures via API

  @requires_testuser
  Scenario: cas user (admin) => access users.json with api key => success
    Given the user is member of the admin user group
    And the user has an internal default redmine account
    When the user request the user.json from Redmine via API key
    Then the user receives the user.json as response

  @requires_testuser
  Scenario: cas user => access users.json with api key => unauthorized
    Given the user is not member of the admin user group
    And the user has an internal default redmine account
    When the user request the user.json from Redmine via API key
    Then the user receives an unauthorized access response

  @requires_testuser
  Scenario: cas user + internal special redmine admin account => access users.json with api key => success
    Given the user is not member of the admin user group
    And the user has an internal redmine account with admin privileges granted by another admin
    When the user request the user.json from Redmine via API key
    Then the user receives the user.json as response

  @requires_testuser
  Scenario: cas user + internal special redmine admin account => take admin right in redmine => access users.json with api key => unauthorized
    Given the user is not member of the admin user group
    And the user has an internal redmine account with admin privileges granted by another admin
    When the admin removes the admin privileges from the user via redmine
    And the user request the user.json from Redmine via API key
    Then the user receives an unauthorized access response

  @requires_testuser
  Scenario: cas user + internal special redmine admin account => take admin right in redmine => promote to ces admin => access users.json with api key => success
    Given the user is not member of the admin user group
    And the user has an internal redmine account with admin privileges granted by another admin
    When the admin removes the admin privileges from the user via redmine
    And the user is added as a member to the ces admin group
    And the user logs into the CES
    And the user request the user.json from Redmine via API key
    Then the user receives the user.json as response