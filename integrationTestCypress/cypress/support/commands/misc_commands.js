// ***********************************************
// commands for the login/logout flow
// ***********************************************
let doguName = "redmine"

/**
 * Log the test user in the cas.
 */
const login = (username, password) => {
    cy.visit("/" + doguName)

    cy.clickWarpMenuCheckboxIfPossible()

    cy.get('input[name="username"]').type(username)
    cy.get('input[name="password"]').type(password)
    cy.get('input[name="submit"]').click()
    cy.wait(1000)
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
        cy.get('input[name="submit"]').click()
        cy.wait(1000)
    })
}

/**
 * Log the testuser out of the cas.
 */
const logout = () => {
    cy.visit("/cas/logout")
    cy.wait(1000)
}

/**
 * Handles the warp menu tooltip by clicking the 'do not show again' checkbox on the first time.
 */
const clickWarpMenuCheckboxIfPossible = () => {
    cy.get('div[id="warp-menu-container"]').then(function (container) {
        let warpContainer = container.children( ".warp-menu-column-tooltip")
        if (warpContainer.length == 1) {
            cy.get('input[type="checkbox"]').click(true)
        }
    })
}

Cypress.Commands.add("login", login)
Cypress.Commands.add("loginAdmin", login)
Cypress.Commands.add("logout", logout)
Cypress.Commands.add("clickWarpMenuCheckboxIfPossible", clickWarpMenuCheckboxIfPossible)