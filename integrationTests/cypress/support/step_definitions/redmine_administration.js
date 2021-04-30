const {
    Given,
    When,
    Then
} = require("cypress-cucumber-preprocessor/steps");
const env = require('@cloudogu/dogu-integration-test-library/lib/environment_variables')

//
//
// Given
//
//

Given(/^the user has an internal redmine account with admin privileges granted by another admin$/, function () {
    cy.fixture("testuser_data").then(function (testUser) {
        cy.login(testUser.username, testUser.password)
        cy.logout()
        cy.redmineGiveAdminRights(testUser.username)
    })
});