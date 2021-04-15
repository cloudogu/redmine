Feature: Redmine has some Features TODO

  Scenario: a user is granted admin privileges
    Given the user is logged in
    When navigate to users page
    And  the user that should be granted admin priviliges is present
    And the user is selected
    And the button is selectable
    And the grant-admin-rights-form is submitted
    Then the user has admin priviliges