Feature: Redmine install and uninstall plugins functionality

  Scenario: an admin user checks whether the default plugins are installed
    Given the user has valid login credentials
    When the admin user logs into redmine
    And the admin navigates to the plugin overview
    Then the plugin "redmine_extended_rest_api" is installed
    And the plugin "redmine_cas" is installed
    And the plugin "redmine_activerecord_session_store" is installed

  Scenario: an admin user checks whether a custom plugin is installed
    Given the user has valid login credentials
    When the admin user logs into redmine
    And the admin navigates to the plugin overview
    Then the plugin "redmine_noop_plugin" is installed

  @after_plugin_deletion
  Scenario: an admin user checks whether a custom plugin is not installed
    Given the user has valid login credentials
    When the admin user logs into redmine
    And the admin navigates to the plugin overview
    Then the plugin "redmine_noop_plugin" is not installed

  @UpgradeTest
  Scenario: an admin user checks whether the default plugins are installed after upgrade
    Given the user has valid login credentials
    When the admin user logs into redmine
    And the admin navigates to the plugin overview
    Then the plugin "redmine_extended_rest_api" is installed in version "1.1.0"
    And the plugin "redmine_cas" is installed in version "2.0.0"
    And the plugin "redmine_activerecord_session_store" is installed in version "0.1.0"

  @UpgradeTest
  Scenario: an admin user checks whether a custom plugin is installed after upgrade
    Given the user has valid login credentials
    When the admin user logs into redmine
    And the admin navigates to the plugin overview
    Then the plugin "redmine_noop_plugin" is installed in version "0.0.1"