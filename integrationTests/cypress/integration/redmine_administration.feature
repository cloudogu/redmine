Feature: Administrative Procedures

  @requires_testuser
  Scenario: An ordinary CAS user logs into redmine for the first time and a normal redmine account is created
    Given the user is not member of the admin user group
    And the user has no internal redmine account
    And the user is logged out of the CES
    When the user logs into the CES
    Then the user has an internal redmine account with default privileges

  @requires_testuser
  Scenario: An admin CAS user logs into redmine for the first time and consequently an admin redmine account is created
    Given the user is member of the admin user group
    And the user has no internal redmine account
    And the user is logged out of the CES
    When the user logs into the CES
    Then the user has an internal redmine account with admin privileges

  @requires_testuser
  Scenario: A normal CAS user, with existing normal redmine account logs in to redmine where no changes to his permissions takes place.
    Given the user is not member of the admin user group
    And the user has an internal default redmine account
    And the user is logged out of the CES
    When the user logs into the CES
    Then the user has an internal redmine account with default privileges

  @requires_testuser
  Scenario: A regular CAS user, with existing admin redmine account granted by CAS logs into redmine and his redmine account is rightfully demoted to a regular account
    Given the user is not member of the admin user group
    And the user has an internal admin redmine account
    And the user is logged out of the CES
    When the user logs into the CES
    Then the user has an internal redmine account with default privileges

  @requires_testuser
  Scenario: An admin CAS user, with existing normal redmine account logs into redmine and his redmine account is rightfully promoted to an admin account"
    Given the user is member of the admin user group
    And the user has an internal default redmine account
    And the user is logged out of the CES
    When the user logs into the CES
    Then the user has an internal redmine account with admin privileges

  @requires_testuser
  Scenario: An admin CAS user, with existing admin redmine account granted by CAS logs in to redmine where no changes to his permissions takes place.
    Given the user is member of the admin user group
    And the user has an internal admin redmine account
    And the user is logged out of the CES
    When the user logs into the CES
    Then the user has an internal redmine account with admin privileges

  @requires_testuser
  Scenario: A regular CAS user, with existing special admin redmine account granted internally logs into redmine and preserves admin privileges
    Given the user is not member of the admin user group
    And the user has an internal redmine account with admin privileges granted by another admin
    And the user is logged out of the CES
    When the user logs into the CES
    Then the user has an internal redmine account with admin privileges

  @requires_testuser
  Scenario: A regular CAS user with special internal redmine admin privileges loses them after begin assigned and unassigned to the ces admin user-group.
    Given the user is not member of the admin user group
    And the user has an internal redmine account with admin privileges granted by another admin
    And the user is logged out of the CES
    When the user is added as a member to the ces admin group
    And the user logs into the CES
    And the user logs out of the CES
    And the user is removed as a member from the ces admin group
    And the user logs into the CES
    Then the user has an internal redmine account with default privileges
