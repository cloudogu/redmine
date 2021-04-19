const {
    Given,
    When,
    Then
} = require("cypress-cucumber-preprocessor/steps");

// By default we assume the user to have valid credentials
let fixtureUsedToLogin = "ces_admin_data"
// The response is used to verify the outcome of a request
let apikeyUsedForLogin = null
// The response is used to verify the outcome of a request
let authenticationResponse = null

//
//
// Given
//
//

Given(/^the user has valid login credentials$/, function () {
    fixtureUsedToLogin = "ces_admin_data"
});

Given(/^the user has invalid login credentials$/, function () {
    fixtureUsedToLogin = "invalid_testuser_data"
});

Given(/^the user has a valid api key$/, function () {

    fixtureUsedToLogin = "ces_admin_data"

    cy.fixture("ces_admin_data").then(userdata => {
        cy.redmineGetCurrentUserJsonWithBasic(userdata.username, userdata.password).then(function (response) {
            expect(response.status).to.eq(200)
            apikeyUsedForLogin = response.body.user.api_key
        })
    });

});

Given(/^the user has an invalid api key$/, function () {
    fixtureUsedToLogin = "invalid_testuser_data"
    apikeyUsedForLogin = "invalid_key"
});

//
//
// When
//
//

When(/^the user authenticate via basic authentication$/, function () {
    cy.fixture(fixtureUsedToLogin).then(userdata => {
        cy.redmineGetCurrentUserJsonWithBasic(userdata.username, userdata.password).then(function (response) {
            authenticationResponse = response
        })
    });
});

When(/^the user authenticate via api key$/, function () {
    cy.redmineGetCurrentUserJsonWithKey(apikeyUsedForLogin).then(function (response) {
        authenticationResponse = response
    })
});

//
//
// Then
//
//

Then(/^the user receives a json response with valid cas attributes$/, function () {
    expect(authenticationResponse.status).to.eq(200)
    expect(authenticationResponse.body).to.have.property('user')
    cy.fixture(fixtureUsedToLogin).then(userdata => {
        console.log(JSON.stringify(authenticationResponse.body))
        expect(authenticationResponse.body.user).to.have.property('login', userdata.username)
    });
});

Then(/^the user receives a (\d+) response$/, function () {
    expect(authenticationResponse.status).to.eq(401)
});