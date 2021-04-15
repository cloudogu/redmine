// ***********************************************
// commands for the usermgt
// ***********************************************

// ***********************************************
// REST - /api/account
// ***********************************************

/**
 * Return the user account that is authenticated by the given credentials.
 * @param {String} username - The username of the account.
 * @param {String} password - The password of the account.
 */
const usermgtGetAccount = (username, password) => {
    cy.request({
        method: "GET",
        url: Cypress.config().baseUrl + "/usermgt/api/account",
        auth: {
            'user': username,
            'pass': password
        }
    }).then((response) => {
        expect(response.status).to.eq(200)
        return response.body
    })
}

// ***********************************************
// REST - /api/users
// ***********************************************

/**
 * Return the user defined by the username.
 * @param {String} username - The username of the user.
 */
const usermgtGetUser = (username) => {
    cy.fixture("ces_admin_data.json").then(function (admindata) {
        cy.request({
            method: "GET",
            url: Cypress.config().baseUrl + "/usermgt/api/users/" + username,
            auth: {
                'user': admindata.username,
                'pass': admindata.password
            }
        }).then((response) => {
            expect(response.status).to.eq(200)
            return response.body
        })
    })
}

/**
 * Creates the user defined in in the given user data object parameter.
 * A failed request is not tolerated and fails the test.
 * @param {String} username - The username for the user.
 * @param {String} givenname - The real given name of the user.
 * @param {String} surname - The real surname of the user.
 * @param {String} displayName - The displayname for the user.
 * @param {String} mail - The E-Mail for the user.
 * @param {String} password - The password for the user.
 */
const usermgtCreateUser = (username, givenname, surname, displayName, mail, password) => {
    cy.fixture("ces_admin_data.json").then(function (admindata) {
        cy.request({
            method: "POST",
            url: Cypress.config().baseUrl + "/usermgt/api/users/",
            followRedirect: false,
            auth: {
                'user': admindata.username,
                'pass': admindata.password
            },
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: {
                'username': username,
                'givenname': givenname,
                'surname': surname,
                'displayName': displayName,
                'mail': mail,
                'password': password,
                'memberOf': []
            }
        }).then((response) => {
            expect(response.status).to.eq(201)
        })
    })
}


/**
 * Deletes the user given by the username.
 * A failed request is not tolerated and fails the test.
 * @param {String} username - The username of the user that should be deleted.
 */
const usermgtDeleteUser = (username) => {
    cy.fixture("ces_admin_data.json").then(function (admindata) {
        cy.request({
            method: "DELETE",
            url: Cypress.config().baseUrl + "/usermgt/api/users/" + username,
            auth: {
                'user': admindata.username,
                'pass': admindata.password
            }
        }).then((response) => {
            expect(response.status).to.eq(204)
        })
    })
}

/**
 * Tries to deletes the user given by the username.
 * A failed request is tolerated and does not fail the test.
 * @param {String} username - The username of the user that should be deleted.
 */
const usermgtTryDeleteUser = (username) => {
    cy.fixture("ces_admin_data.json").then(function (admindata) {
        cy.request({
            method: "DELETE",
            url: Cypress.config().baseUrl + "/usermgt/api/users/" + username,
            failOnStatusCode: false,
            auth: {
                'user': admindata.username,
                'pass': admindata.password
            }
        })
    })
}

// ***********************************************
// REST - /api/groups
// ***********************************************

/**
 * Returns the group defined by the given name.
 * A failed request is not tolerated and fails the test.
 * @param {String} name - The name of the group that should be retrieved.
 */
const usermgtGetGroup = (name) => {
    cy.fixture("ces_admin_data.json").then(function (admindata) {
        cy.request({
            method: "POST",
            url: Cypress.config().baseUrl + "/usermgt/api/groups/" + name,
            followRedirect: false,
            auth: {
                'user': admindata.username,
                'pass': admindata.password
            }
        }).then((response) => {
            expect(response.status).to.eq(201)
            return response.body
        })
    })
}

/**
 * Creates a new group in the usermgt.
 * A failed request is not tolerated and fails the test.
 * @param {String} name - The name for the new group.
 * @param {String} description - The description for the new group.
 */
const usermgtCreateGroup = (name, description) => {
    cy.fixture("ces_admin_data.json").then(function (admindata) {
        cy.request({
            method: "POST",
            url: Cypress.config().baseUrl + "/usermgt/api/groups",
            followRedirect: false,
            auth: {
                'user': admindata.username,
                'pass': admindata.password
            },
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: {
                'name': name,
                'description': description,
                'members': []
            }
        }).then((response) => {
            expect(response.status).to.eq(201)
        })
    })
}

/**
 * Deletes a group from the usermgt.
 * A failed request is not tolerated and fails the test.
 * @param {String} groupName - The name of the group that should be deleted.
 */
const usermgtDeleteGroup = (groupName) => {
    cy.fixture("ces_admin_data.json").then(function (admindata) {
        cy.request({
            method: "DELETE",
            url: Cypress.config().baseUrl + "/usermgt/api/groups/" + groupName,
            followRedirect: false,
            auth: {
                'user': admindata.username,
                'pass': admindata.password
            }
        }).then((response) => {
            expect(response.status).to.eq(204)
        })
    })
}

/**
 * Tries to delete a group from the usermgt.
 * A failed request is tolerated and does not fail the test.
 * @param {String} groupName - The name of the group that should be deleted.
 */
const usermgtTryDeleteGroup = (groupName) => {
    cy.fixture("ces_admin_data.json").then(function (admindata) {
        cy.request({
            method: "DELETE",
            url: Cypress.config().baseUrl + "/usermgt/api/groups/" + groupName,
            followRedirect: false,
            failOnStatusCode: false,
            auth: {
                'user': admindata.username,
                'pass': admindata.password
            }
        })
    })
}

/**
 * Adds the given user as a member to the given group. Both user and groups need to exist for a successful request.
 * A failed request is not tolerated and fails the test.
 * @param {String} groupName - The name of the target group.
 * @param {String} username  - The name of the user that should be added to the group.
 */
const usermgtAddMemberToGroup = (groupName, username) => {
    cy.fixture("ces_admin_data.json").then(function (admindata) {
        cy.request({
            method: "POST",
            url: Cypress.config().baseUrl + "/usermgt/api/groups/" + groupName + "/members/" + username,
            auth: {
                'user': admindata.username,
                'pass': admindata.password
            }
        }).then((response) => {
            expect(response.status).to.eq(204)
        })
    })
}

/**
 * Removes the given user from the given group.
 * A failed request is not tolerated and fails the test.
 * @param {String} groupName - The name of the target group.
 * @param {String} username  - The name of the user that should be removed from the group.
 */
const usermgtRemoveMemberFromGroup = (groupName, username) => {
    cy.fixture("ces_admin_data.json").then(function (admindata) {
        cy.request({
            method: "DELETE",
            url: Cypress.config().baseUrl + "/usermgt/api/groups/" + groupName + "/members/" + username,
            auth: {
                'user': admindata.username,
                'pass': admindata.password
            }
        }).then((response) => {
            expect(response.status).to.eq(204)
        })
    })
}

// /api/account
Cypress.Commands.add("usermgtGetAccount", usermgtGetAccount)

// /api/users/
Cypress.Commands.add("usermgtGetUser", usermgtGetUser)
Cypress.Commands.add("usermgtCreateUser", usermgtCreateUser)
Cypress.Commands.add("usermgtDeleteUser", usermgtDeleteUser)
Cypress.Commands.add("usermgtTryDeleteUser", usermgtTryDeleteUser)

// /api/groups
Cypress.Commands.add("usermgtGetGroup", usermgtGetGroup)
Cypress.Commands.add("usermgtCreateGroup", usermgtCreateGroup)
Cypress.Commands.add("usermgtDeleteGroup", usermgtDeleteGroup)
Cypress.Commands.add("usermgtTryDeleteGroup", usermgtTryDeleteGroup)
Cypress.Commands.add("usermgtAddMemberToGroup", usermgtAddMemberToGroup)
Cypress.Commands.add("usermgtRemoveMemberFromGroup", usermgtRemoveMemberFromGroup)