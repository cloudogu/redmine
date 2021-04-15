// ***********************************************
// commands for redmine
// ***********************************************

/**
 * Retrieves the user json of the user via a basic authentication. Both user and password need to exist for a successful request.
 * A failed request is not tolerated and fails the test.
 * @param {String} username - The username of the user.
 * @param {String} password  - The password of the user.
 * @returns a promise for the request
 */
const redmineGetCurrentUserJsonWithBasic = (username, password) => {
    return cy.request({
        method: "GET",
        url: Cypress.config().baseUrl + "/redmine/users/current.json",
        auth: {
            'user': username,
            'pass': password
        },
        failOnStatusCode: false
    })
}

/**
 * Retrieves the user json of the user via an api key authentication. The api key needs to exist for a successful request.
 * A failed request is not tolerated and fails the test.
 * @param {String} apikey - The api key of the user.
 * @returns a promise for the request
 */
const redmineGetCurrentUserJsonWithKey = (apikey) => {
    return cy.request({
        method: "GET",
        url: Cypress.config().baseUrl + "/users/current.json",
        headers: {
            'X-Redmine-API-Key': apikey,
        },
        failOnStatusCode: false
    })
}

// /users/current.json
Cypress.Commands.add("redmineGetCurrentUserJsonWithBasic", redmineGetCurrentUserJsonWithBasic)
Cypress.Commands.add("redmineGetCurrentUserJsonWithKey", redmineGetCurrentUserJsonWithKey)