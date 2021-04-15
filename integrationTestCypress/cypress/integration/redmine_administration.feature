Feature: test

  @requires_testuser
  Scenario: the user is admin in general = admin in redmine
    Given the user is member of the admin user group
    And the user is logged out of the CES

  @requires_testuser
  Scenario: the user is no admin in general = no admin in redmine
    Given the user is not member of the admin user group
    And the user is logged out of the CES

  @requires_testuser
  Scenario: user gets admin rights in redmine
    Given the user is not member of the admin user group
    And the user is logged out of the CES

  @requires_testuser
  Scenario: the user preserves redmine admin privileges after demotion from user management admin group
    Given the user is not member of the admin user group
    And the user is not redmine admin

  // user gets admin rights in redmine and then in user management = take rights in user management

  @requires_testuser
  Scenario: user gets admin rights in redmine = take rights in redmine

  @requires_testuser
  Scenario: user gets admin rights in redmine and then in usermanagement = take rights in redmine


  cas user         + no redmine user => login => create normal redmine account
  cas user (admin) + no redmine user => login => create admin redmine account

  cas user         + internal redmine user => login => ---
  cas user         + internal admin redmine user => login => demote to default redmine account
  //TODO: Was ist hier korrekt? Entziehen der REche oder behalten der Redmine Admin Rechte

  cas user (admin) + internal redmine user => login => promote to admin redmine account
  cas user (admin) + internal admin redmine user => login => ---
