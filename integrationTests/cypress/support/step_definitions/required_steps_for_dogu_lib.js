const {
    When,
    Then
} = require("@badeball/cypress-cucumber-preprocessor");
const env = require('@cloudogu/dogu-integration-test-library/lib/environment_variables')

// Loads all steps from the dogu integration library into this project
const doguTestLibrary = require('@cloudogu/dogu-integration-test-library')
doguTestLibrary.registerSteps()

//Implement all necessary steps fore dogu integration test library
When(/^the user clicks the dogu logout button$/, function () {
    cy.redmineLogout()
});

Then(/^the user has no administrator privileges in the dogu$/, function () {
    cy.fixture('testuser_data').then(userdata => {
        cy.redmineGetCurrentUserJsonWithBasic(userdata.username, userdata.password).then(function (response) {
            expect(response.status).to.eq(200)
            expect(response.body).to.have.property('user')
            expect(response.body.user).to.have.property('login', userdata.username)
            // Only administrators have access to the status field
            expect(response.body.user).to.not.have.property('status')
        })
    });
});

Then(/^the user has administrator privileges in the dogu$/, function () {
    cy.fixture('testuser_data').then(userdata => {
        cy.redmineGetCurrentUserJsonWithBasic(userdata.username, userdata.password).then(function (response) {
            expect(response.status).to.eq(200)
            expect(response.body).to.have.property('user')
            expect(response.body.user).to.have.property('login', userdata.username)
            // Only administrators have access to the status field
            expect(response.body.user).to.have.property('status')
        })
    });
});