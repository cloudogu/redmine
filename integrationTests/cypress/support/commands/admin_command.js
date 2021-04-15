/**
 * create a testuser
 */
const createUser = () => {
    const url = "/usermgt/api/users/"

    cy.fixture("user_data").then(function (user_data) {

        // https://docs.cypress.io/api/commands/request#Arguments
        const options = {
            method: "POST",
            url: url,
            headers: {"Content-Type": "application/json;charset=UTF-8"},
            auth: user_data.auth,
            data: user_data.data
        }

        cy.request(options);
    });
}

/**
 * remove a testuser
 */
const removeUser = () => {
    cy.fixture("user_data").then(function (user_data) {

        const url = "/usermgt/api/users/" + user_data.data.username;

        // https://docs.cypress.io/api/commands/request#Arguments
        const options = {
            method: "DELETE",
            url: url,
            headers: {"Content-Type": "application/json;charset=UTF-8"},
            auth: user_data.auth,
            data: user_data.data
        }

        cy.request(options);
    });
}
/**
 * put request to the /usermgt/api/users/<usrnme> endpoint which changes the memberOf property for that user
 *
 * @param adminGroups the admin groups which will get updated in the form of memberOf property
 */
const putUserApiRequest = (adminGroups) => {
    cy.fixture("user_data").then(function (user_data) {

        const url = "/usermgt/api/users/" + user_data.data.username;

        user_data.data.memberOf = adminGroups;

        // https://docs.cypress.io/api/commands/request#Arguments
        const options = {
            method: "PUT",
            url: url,
            headers: {"Content-Type": "application/json;charset=UTF-8"},
            auth: user_data.auth,
            data: user_data.data
        }

        cy.request(options).should((response) => {
            expect(response.status).to.eq(204)
        });
    });

}

/**
 * grant a user admin priviliges
 */
const grantAdminRight = () => {
    putUserApiRequest(['CesAdministrators']);
}

/**
 * revoke admin priviliges from a user
 */
const revokeAdminRight = () => {
    putUserApiRequest(['']);
}


Cypress.Commands.add("createUser", createUser);
Cypress.Commands.add("removeUser", removeUser);
Cypress.Commands.add("grantAdminRight", grantAdminRight);
Cypress.Commands.add("revokeAdminRight", revokeAdminRight);
