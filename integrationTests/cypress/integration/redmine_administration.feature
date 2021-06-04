Feature: Administrative Procedures

  @requires_testuser
  Scenario: A regular CAS user, with existing special admin redmine account granted internally logs into redmine and preserves admin privileges
    Given the user is not member of the admin user group
    And the user has an internal redmine account with admin privileges granted by another admin
    And the user is logged out of the CES
    When the user logs into the CES
    Then the user has administrator privileges in the dogu

  @requires_testuser
  Scenario: A regular CAS user with special internal redmine admin privileges loses them after begin assigned and unassigned to the ces admin user-group.
    Given the user is not member of the admin user group
    And the user has an internal redmine account with admin privileges granted by another admin
    And the user is logged out of the CES
    When the user is added as a member to the CES admin group
    And the user logs into the CES
    And the user logs out by visiting the cas logout page
    And the user is removed as a member from the CES admin group
    And the user logs into the CES
    Then the user has no administrator privileges in the dogu
