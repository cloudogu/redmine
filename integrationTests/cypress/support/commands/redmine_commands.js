// ***********************************************
// commands for redmine
// ***********************************************

// ***********************************************
// UI commands for redmine
// ***********************************************

/**
 * Removes the user from redmine via the UI.
 * @param {username} username - The user to delete from redmine
 */
const redmineDeleteUserViaUI = (username) => {
    //login as admin
    cy.loginAdmin()

    // change to users tab
    cy.visit("/redmine/users")

    // select testuser
    cy.get("a").contains(username).click()

    // select icon delete
    cy.get('a[data-method="delete"]').click()

    // fill confirmation username
    cy.get('input[id="confirm"]').type(username)

    // confirm delete
    cy.get('input[name="commit"]').filter(':visible').click()
    cy.redmineLogout()
}


/**
 * Give the redmine account of the given username specific redmine administration privileges.
 * @param {username} username - The user to grant the specific redmine admin privileges
 */
const redmineGiveAdminRights = (username) => {
    //login as admin
    cy.loginAdmin()

    // change to users tab
    cy.visit("/redmine/users")

    // select testuser
    cy.get("a").contains(username).click()

    // click admin box
    cy.get('input[id="user_admin"]').check()

    //save changes
    cy.get('input[type="submit"]').filter(':visible').click({multiple: true})
    cy.redmineLogout()
}

/**
 * Removes the admin privileges from the given redmine account
 * @param {username} username - The user to remove the specific redmine admin privileges from
 */
const redmineRemoveAdminRights = (username) => {
    //login as admin
    cy.loginAdmin()

    // change to users tab
    cy.visit("/redmine/users")

    // select testuser
    cy.get("a").contains(username).click()

    // click admin box
    cy.get('input[id="user_admin"]').uncheck()
    //save changes
    cy.get('input[type="submit"]').filter(':visible').click({multiple: true})
    cy.redmineLogout()
}

/**
 * Logs the user out of the ces via the logout button/anchor.
 */
const redmineLogout = () => {
    cy.get('a[href="/redmine/logout"]').click()
}

Cypress.Commands.add("redmineDeleteUserViaUI", redmineDeleteUserViaUI)
Cypress.Commands.add("redmineGiveAdminRights", redmineGiveAdminRights)
Cypress.Commands.add("redmineLogout", redmineLogout)
Cypress.Commands.add("redmineRemoveAdminRights", redmineRemoveAdminRights)

// ***********************************************
// API commands for redmine
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
 * @param {String} apiKey - The api key of the user.
 * @returns a promise for the request
 */
const redmineGetCurrentUserJsonWithKey = (apiKey) => {
    return cy.request({
        method: "GET",
        url: Cypress.config().baseUrl + "/redmine/users/current.json",
        headers: {
            'X-Redmine-API-Key': apiKey,
        },
        failOnStatusCode: false
    })
}

/**
 * Retrieves the users.json via api request.
 * @param {String} apiKey - The api key of the user used for authorization.
 * @return the response of the request
 */
const redmineGetUsersJson = (apiKey) => {
    return cy.request({
        method: "GET",
        url: Cypress.config().baseUrl + "/redmine/users.json",
        headers: {
            'X-Redmine-API-Key': apiKey,
        },
        failOnStatusCode: false
    })
}

/**
 * Deletes a user from redmine.
 * @param {String} username - The username of the user.
 */
const redmineDeleteUser = (username) => {
    cy.fixture("ces_admin_data.json").then(function (admindata) {

        cy.redmineGetCurrentUserJsonWithBasic(admindata.username, admindata.password).then((responseApiKey) => {
            expect(responseApiKey.status).to.eq(200)
            cy.redmineGetUsersJson(responseApiKey.body.user.api_key).then((response) => {
                expect(response.status).to.eq(200)

                for (var user in response.body.users) {
                    if (user.login === username) {
                        return cy.request({
                            method: "GET",
                            url: Cypress.config().baseUrl + "/redmine/users/" + user.id + ".json",
                            auth: {
                                'user': admindata.username,
                                'pass': admindata.password
                            },
                            failOnStatusCode: false
                        })
                    }
                }
            })
        })
    })
}

// /users/current.json
Cypress.Commands.add("redmineGetCurrentUserJsonWithBasic", redmineGetCurrentUserJsonWithBasic)
Cypress.Commands.add("redmineGetCurrentUserJsonWithKey", redmineGetCurrentUserJsonWithKey)
// /users.json
Cypress.Commands.add("redmineGetUsersJson", redmineGetUsersJson)
// /users/id.json
Cypress.Commands.add("redmineDeleteUser", redmineDeleteUser)
