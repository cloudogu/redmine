Feature: Administrative Procedures

  # Log in the admin to create a redmine user. When redmine has no users it throws unexpected errors when requesting the users.json via API
  Scenario: Create the admin as user in redmine
    When the admin logs into redmine