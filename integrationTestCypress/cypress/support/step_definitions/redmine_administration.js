const {
    Given,
    When,
    Then
} = require("cypress-cucumber-preprocessor/steps");

//
//
// Given
//
//

Given(/^the user is not member of the admin user group$/, function () {
    // default behaviour
});

Given(/^the user has no internal redmine account$/, function () {
    // default behaviour
});

Given(/^the user is member of the admin user group$/, function () {
    cy.fixture("testuser_data").then(function (testUser) {
        cy.promoteAccountToAdmin(testUser.username)
    })
});

Given(/^the user has an internal default redmine account$/, function () {
    cy.fixture("testuser_data").then(function (testUser) {
        cy.login(testUser.username, testUser.password)
        cy.redmineLogout()
    })
});

Given(/^the user has an internal admin redmine account$/, function () {
    cy.fixture("testuser_data").then(function (testUser) {
        cy.fixture("ces_admin_data.json").then(function (adminData) {
            cy.isCesAdmin(testUser.username).then(function (isAdmin) {
                if (isAdmin) {
                    // create internal remine acccount
                    cy.login(testUser.username, testUser.password)
                    cy.redmineLogout()
                } else {
                    // promote -> create internal remine acccount -> demote
                    cy.promoteAccountToAdmin(testUser.username)
                    cy.login(testUser.username, testUser.password)
                    cy.redmineLogout()
                    cy.demoteAccountToDefault(testUser.username)
                }
            })
        })
    })
});


Given(/^the user has an internal redmine account with admin privileges granted by another admin$/, function () {
    cy.fixture("testuser_data").then(function (testUser) {
        cy.login(testUser.username, testUser.password)
        cy.redmineLogout()
        cy.redmineGiveAdminRights(testUser.username)
    })
});

Given(/^the user is logged in to the CES$/, function () {
    cy.fixture("testuser_data").then(function (testUser) {
        cy.login(testUser.username, testUser.password)
    })
});

Given(/^the user is logged out of the CES$/, function () {
    cy.redmineLogout()
});

//
//
// When
//
//

When(/^the user logs into the CES$/, function () {
    cy.fixture('testuser_data').then(userdata => {
        cy.login(userdata.username, userdata.password)
    });
});

When(/^the user is added as a member to the ces admin group$/, function () {
    cy.fixture("testuser_data").then(function (testUser) {
        cy.promoteAccountToAdmin(testUser.username)
    })
});

When(/^the user logs out of Redmine$/, function () {
    cy.redmineLogout()
});

When(/^the user is removed as a member from the ces admin group$/, function () {
    cy.fixture("testuser_data").then(function (testUser) {
        cy.demoteAccountToDefault(testUser.username)
    })
});

//
//
// Then
//
//
Then(/^the user has an internal redmine account with default privileges$/, function () {
    cy.fixture('testuser_data').then(userdata => {
        cy.redmineGetCurrentUserJsonWithBasic(userdata.username, userdata.password).then(function (response) {
            expect(response.status).to.eq(200)
            expect(response.body).to.have.property('user')
            expect(response.body.user).to.have.property('login', userdata.username)
            // Only administrators have access to the status field
            expect(response.body.user).to.not.have.property('status')
        })
    });
});

Then(/^the user has an internal redmine account with admin privileges$/, function () {
    cy.fixture('testuser_data').then(userdata => {
        cy.redmineGetCurrentUserJsonWithBasic(userdata.username, userdata.password).then(function (response) {
            expect(response.status).to.eq(200)
            expect(response.body).to.have.property('user')
            expect(response.body.user).to.have.property('login', userdata.username)
            // Only administrators have access to the status field
            expect(response.body.user).to.have.property('status')
        })
    });
});