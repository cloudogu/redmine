// ***********************************************
// commands for the login/logout flow
// ***********************************************
let doguName = "redmine"

/**
 * Logs a given user in the cas.
 * @param {String} username - The username of the user.
 * @param {String} password - The password for the user.
 */
const login = (username, password) => {
    cy.visit("/" + doguName)

    cy.clickWarpMenuCheckboxIfPossible()

    cy.get('input[name="username"]').type(username)
    cy.get('input[name="password"]').type(password)
    cy.get('button[name="submit"]').click()
}


/**
 * Log the admin user defined in the ces_admin_data.json in the cas.
 */
const loginAdmin = () => {
    cy.fixture("ces_admin_data").then(function (admin) {
        cy.visit("/" + doguName)

        cy.clickWarpMenuCheckboxIfPossible()

        cy.get('input[name="username"]').type(admin.username)
        cy.get('input[name="password"]').type(admin.password)
        cy.get('button[name="submit"]').click()
    })
}

/**
 * Log the current user out of the cas via back-channel logout.
 */
const logout = () => {
    cy.visit("/cas/logout")
}

/**
 * Handles the warp menu tooltip by clicking the 'do not show again' checkbox on the first time.
 */
const clickWarpMenuCheckboxIfPossible = () => {
    cy.get('div[id="warp-menu-container"]').then(function (container) {
        let warpContainer = container.children( ".warp-menu-column-tooltip")
        if (warpContainer.length === 1) {
            cy.get('input[type="checkbox"]').click(true)
        }
    })
}

/**
 * Return whether a user has ces administrator privileges.
 * @param {String} username - The username of the user to check.
 */
const isCesAdmin = (username) => {
    cy.fixture("ces_admin_data.json").then(function (adminData) {
        cy.usermgtGetUser(username).then(function (response) {
            for (var element of response.memberOf) {
                if (element === adminData.admingroup) {
                    return true
                }
            }
            return false
        })
    });
}

/**
 * Promotes an account to a ces admin account. If the given account is already admin it does nothing.
 * @param {String} username - The username of the user to promote.
 */
const promoteAccountToAdmin = (username) => {
    cy.fixture("ces_admin_data.json").then(function (adminData) {
        cy.isCesAdmin(username).then(function (isAdmin) {
            if (!isAdmin) {
                //promote
                cy.usermgtAddMemberToGroup(adminData.admingroup, username)
            }
        })
    })
}

/**
 * Demotes an account to a ces default account. If the given account is already a default account it does nothing.
 * @param {String} username - The username of the user to demote.
 */
const demoteAccountToDefault = (username) => {
    cy.fixture("ces_admin_data.json").then(function (adminData) {
        cy.isCesAdmin(username).then(function (isAdmin) {
            if (isAdmin) {
                //demote
                cy.usermgtRemoveMemberFromGroup(adminData.admingroup, username)
            }
        })
    })
}

Cypress.Commands.add("clickWarpMenuCheckboxIfPossible", clickWarpMenuCheckboxIfPossible)
Cypress.Commands.add("demoteAccountToDefault", demoteAccountToDefault)
Cypress.Commands.add("isCesAdmin", isCesAdmin)
Cypress.Commands.add("login", login)
Cypress.Commands.add("loginAdmin", loginAdmin)
Cypress.Commands.add("logout", logout)
Cypress.Commands.add("promoteAccountToAdmin", promoteAccountToAdmin)