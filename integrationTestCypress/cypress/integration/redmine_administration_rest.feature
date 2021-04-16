Feature: test

  @requires_testuser
  Scenario: cas user (admin) => access users.json with api key => success
    Given the user is member of the admin user group
    And the user has an internal default redmine account
    And the user is logged in to the CES
    When the user request the user.json from Redmine via API key
    Then the user receives the user.json as response

  @requires_testuser
  Scenario: cas user => access users.json with api key => unauthorized
    Given the user is not member of the admin user group
    And the user has an internal default redmine account
    And the user is logged in to the CES
    When the user request the user.json from Redmine via API key
    Then the user receives an unauthorized access response

  # TODO: not working as expected -> redmine_cas plugin bug?
#  @requires_testuser
#  Scenario: cas user + internal special redmine admin account => access users.json with api key => success
#    Given the user is not member of the admin user group
#    And the user has an internal redmine account with admin privileges granted by another admin
#    And the user is logged in to the CES
#    When the user request the user.json from Redmine via API key
#    Then the user receives the user.json as response
#
  # TODO: not tested (fully implemented)
#  @requires_testuser
#  Scenario: cas user + internal special redmine admin account => take admin right in redmine => access users.json with api key => unauthorized
#    Given the user is not member of the admin user group
#    And the user has an internal default redmine account
#    And the user is logged in to the CES
#    When the user request the user.json from Redmine via API key
#    Then the user receives an unauthorized access response
#
  # TODO: not tested (fully implemented)
#  @requires_testuser
#  Scenario: cas user + internal special redmine admin account => take admin right in redmine => promote to ces admin => access users.json with api key => success
#    Given the user is not member of the admin user group
#    And the user has an internal default redmine account
#    And the user is logged in to the CES
#    When the user request the user.json from Redmine via API key
#    Then the user receives the user.json as response