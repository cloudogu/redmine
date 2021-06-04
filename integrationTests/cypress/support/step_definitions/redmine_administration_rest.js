const {
    When,
    Then
} = require("cypress-cucumber-preprocessor/steps");

// The response is used to verify the outcome of a request
let authenticationResponse = null

//
//
// When
//
//
When(/^the user request the user\.json from Redmine via API key$/, function () {
    cy.fixture("testuser_data").then(function (testUser) {
        // retrieve api key
        cy.redmineGetCurrentUserJsonWithBasic(testUser.username, testUser.password).then(function (response) {
            let api_key = response.body.user.api_key
            console.log(JSON.stringify(response.body.user))
            cy.redmineGetUsersJson(api_key, false).then(function (usersResponse) {
                authenticationResponse = usersResponse
            })
        })

    })
});


When(/^the admin removes the admin privileges from the user via redmine$/, function () {
    cy.fixture("testuser_data").then(function (testUser) {
        cy.redmineRemoveAdminRights(testUser.username)
    })
});
//
//
// Then
//
//
Then(/^the user receives the user\.json as response$/, function () {
    expect(authenticationResponse.status).to.eq(200)
});

Then(/^the user receives an unauthorized access response$/, function () {
    expect(authenticationResponse.status).to.eq(403)
});