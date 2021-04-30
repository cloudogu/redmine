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
 * Removes the admin privileges from the given redmine account.
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
