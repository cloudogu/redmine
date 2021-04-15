const {
    Given,
    When,
    Then
} = require("cypress-cucumber-preprocessor/steps");

// By default we assume the user to have valid credentials
let fixtureUsedToLogin = "valid_testuser_data"
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
    fixtureUsedToLogin = "valid_testuser_data"
});

Given(/^the user has invalid login credentials$/, function () {
    fixtureUsedToLogin = "invalid_testuser_data"
});

Given(/^the user has a valid api key$/, function () {
    cy.fixture("valid_testuser_data").then(userdata => {
        cy.redmineGetCurrentUserJsonWithBasic(userdata.username, userdata.password).then(function (response) {
            expect(response.status).to.eq(200)
            console.log(JSON.stringify(response.body.user))
            console.log("API_KEY:" + response.body.user.api_key)
            apikeyUsedForLogin = response.body.user.api_key
        })
    });

});

Given(/^the user has an invalid api key$/, function () {
    apikeyUsedForLogin = "invalid_key"
    console.log("API_KEY:" + response.body.api_key)
});

//
//
// When
//
//

When(/^the user authenticate via basic authentication$/, function () {
    cy.fixture(fixtureUsedToLogin).then(userdata => {
        cy.redmineGetCurrentUserJsonWithBasic(userdata.username, userdata.password).then(function (response) {
            authenticationResponse=response
        })
    });
});

When(/^the user authenticate via api key$/, function () {
    cy.redmineGetCurrentUserJsonWithKey(apikeyUsedForLogin).then(function (response) {
        authenticationResponse=response
    })
});

//
//
// Then
//
//

Then(/^the user receives a json response with valid cas attributes$/, function () {
    expect(authenticationResponse.status).to.eq(200)
});

Then(/^the user receives a (\d+) response$/, function () {
    expect(authenticationResponse.status).to.eq(401)
});