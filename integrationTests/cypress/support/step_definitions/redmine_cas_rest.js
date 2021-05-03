const {
    Given,
    When,
    Then
} = require("cypress-cucumber-preprocessor/steps");
const env = require('@cloudogu/dogu-integration-test-library/lib/environment_variables')

// By default we assume the user to have valid credentials
let fixtureUsedToLogin = "admin"
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
    fixtureUsedToLogin = "admin"
});

Given(/^the user has invalid login credentials$/, function () {
    fixtureUsedToLogin = "invalid_testuser_data"
});

Given(/^the user has a valid api key$/, function () {
    if (fixtureUsedToLogin === "admin") {
        cy.redmineGetCurrentUserJsonWithBasic(env.GetAdminUsername(), env.GetAdminPassword()).then(function (response) {
            console.log(response)
            expect(response.status).to.eq(200)
            apikeyUsedForLogin = response.body.user.api_key
        })
    } else {
        cy.fixture(fixtureUsedToLogin).then(userdata => {
            cy.redmineGetCurrentUserJsonWithBasic(userdata.username, userdata.password).then(function (response) {
                expect(response.status).to.eq(200)
                apikeyUsedForLogin = response.body.user.api_key
            })
        });
    }

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
    if (fixtureUsedToLogin === "admin") {
        cy.redmineGetCurrentUserJsonWithBasic(env.GetAdminUsername(), env.GetAdminPassword(), false).then(function (response) {
            authenticationResponse = response
        })
    } else {
        cy.fixture(fixtureUsedToLogin).then(userdata => {
            cy.redmineGetCurrentUserJsonWithBasic(userdata.username, userdata.password, false).then(function (response) {
                authenticationResponse = response
            })
        });
    }
});

When(/^the user authenticate via api key$/, function () {
    cy.redmineGetCurrentUserJsonWithKey(apikeyUsedForLogin, false).then(function (response) {
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
    if (fixtureUsedToLogin === "admin") {
        expect(authenticationResponse.body.user).to.have.property('login', env.GetAdminUsername())
    } else {
        cy.fixture(fixtureUsedToLogin).then(userdata => {
            expect(authenticationResponse.body.user).to.have.property('login', userdata.username)
        });
    }
});

Then(/^the user receives a (\d+) response$/, function () {
    expect(authenticationResponse.status).to.eq(401)
});