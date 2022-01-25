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

//
//
// When
//
//

When(/^the admin logs into redmine$/, function () {
  cy.login(env.GetAdminUsername(), env.GetAdminPassword())
  cy.logout()
});

When(/^the admin user logs into redmine$/, function () {
  cy.login(env.GetAdminUsername(), env.GetAdminPassword())
});

When("the admin navigates to the plugin overview", function () {
  cy.visit("/redmine/admin/plugins")
})

//
//
// Then
//
//

Then("the plugin {string} is installed", name => {
  cy.get("#plugin-" + name).should('exist')
})

Then("the plugin {string} is installed in version {string}", (name, version) => {
  cy.get("#plugin-" + name).within(() => {
    cy.get("td.version span").then(element => {
      expect(element.text()).to.eq(version, "found wrong version for plugin " + name)
    })
  })
})

Then("the plugin {string} is not installed", name => {
  cy.get("#plugin-" + name).should('not.exist')
})
