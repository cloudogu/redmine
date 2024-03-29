/**
 * Deletes a user from the dogu via an API call.
 * @param {String} username - The username of the user.
 * @param {boolean} exitOnFail - Determines whether the test should fail when the request did not succeed. Default: false
 */
const deleteUserFromDoguViaAPI = (username, exitOnFail = false) => {
    cy.redmineDeleteUser(username, exitOnFail)
}

// Implement the necessary commands for the dogu integration test library
Cypress.Commands.add("deleteUserFromDoguViaAPI", deleteUserFromDoguViaAPI)