Feature: test

  @requires_testuser
  Scenario: cas user + no redmine user => login => create normal redmine account
    Given the user is not member of the admin user group
    And the user has no internal redmine account
    And the user is logged out of the CES
    When the user logs into the CES
    Then the user has an internal redmine account with default privileges

  @requires_testuser
  Scenario: cas user (admin) + no redmine user => login => create admin redmine account
    Given the user is member of the admin user group
    And the user has no internal redmine account
    And the user is logged out of the CES
    When the user logs into the CES
    Then the user has an internal redmine account with admin privileges

  @requires_testuser
  Scenario: cas user + internal default redmine user => login => preserves default account
    Given the user is not member of the admin user group
    And the user has an internal default redmine account
    And the user is logged out of the CES
    When the user logs into the CES
    Then the user has an internal redmine account with default privileges

  @requires_testuser
  Scenario: cas user + internal cas-admin redmine user => login => demote to default redmine account
    Given the user is not member of the admin user group
    And the user has an internal admin redmine account
    And the user is logged out of the CES
    When the user logs into the CES
    Then the user has an internal redmine account with default privileges

  @requires_testuser
  Scenario: cas user (admin) + internal default redmine user => login => promote to cas-admin redmine account
    Given the user is member of the admin user group
    And the user has an internal default redmine account
    And the user is logged out of the CES
    When the user logs into the CES
    Then the user has an internal redmine account with admin privileges

  @requires_testuser
  Scenario: cas user (admin) + internal cas-admin redmine user => login => preserves admin account
    Given the user is member of the admin user group
    And the user has an internal admin redmine account
    And the user is logged out of the CES
    When the user logs into the CES
    Then the user has an internal redmine account with admin privileges

  @requires_testuser
  Scenario: cas user + internal special-admin redmine user => login => has admin access
    Given the user is not member of the admin user group
    And the user has an internal redmine account with admin privileges granted by another admin
    And the user is logged out of the CES
    When the user logs into the CES
    Then the user has an internal redmine account with admin privileges

  @requires_testuser
  Scenario: cas user + internal special-admin redmine user => login/out+promote+login/out+demote+login/out => loses special administrator rights
    Given the user is not member of the admin user group
    And the user has an internal redmine account with admin privileges granted by another admin
    And the user is logged out of the CES
    When the user is added as a member to the ces admin group
    And the user logs into the CES
    And the user logs out of the CES
    And the user is removed as a member from the ces admin group
    And the user logs into the CES
    Then the user has an internal redmine account with default privileges
