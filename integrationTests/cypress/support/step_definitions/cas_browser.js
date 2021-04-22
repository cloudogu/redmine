const {
    Given,
    When,
    Then
} = require("cypress-cucumber-preprocessor/steps");

let temp_user
let temp_password

//
//
// Given
//
//

Given(/^the admin is logged in to the CES$/, function () {
    cy.fixture("ces_admin_data").then(function (testUser) {
        cy.login(testUser.username, testUser.password)
    })
});

Given(/^the admin is logged out of the CES$/, function () {
    cy.logout()
});

//
//
// When
//
//

When(/^the user opens the redmine dogu start page$/, function () {
    cy.visit("/redmine")
});

When(/^the user types in wrong login credentials$/, function () {
    temp_user = "RaNd0mUSR_?123"
    temp_password = "RaNd0mPWöäü_?123"

});

When(/^the user types in correct login credentials$/, function () {
    cy.fixture('ces_admin_data').then(userdata => {
        temp_user = userdata.username;
        temp_password = userdata.password;
    });
});

When(/^the user presses the login button$/, function () {
    cy.login(temp_user, temp_password)
});

When(/^the user clicks the logout button$/, function () {
    cy.redmineLogout()
    cy.url().should('contain', Cypress.config().baseUrl + "/cas/logout")
});

When(/^the user opens the CAS logout page$/, function () {
    cy.logout()
});

//
//
// Then
//
//

Then(/^the user is logged in to the dogu$/, function () {
    cy.url().should('contain', Cypress.config().baseUrl + "/redmine")
});

Then(/^the user is redirected to the CAS login page$/, function () {
    cy.url().should('contain', Cypress.config().baseUrl + "/cas/login")
});

Then(/^the user is logged out of the dogu$/, function () {
    // Verify logout by visiting dogu => should redirect to loginpage
    cy.visit("/redmine")
    cy.url().should('contain', Cypress.config().baseUrl + "/cas/login")
});

Then(/^the login page informs user about invalid credentials$/, function () {
    cy.get('div[id="msg"]').contains("Invalid credentials.")
});