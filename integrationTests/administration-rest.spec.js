const config = require('./config');
const AdminFunctions = require('./adminFunctions');
const utils = require('./utils');
const webdriver = require('selenium-webdriver');

jest.setTimeout(30000);
let driver;
let adminFunctions;

// disable certificate validation
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

beforeEach(async() => {
    driver = await utils.createDriver(webdriver);
    adminFunctions = new AdminFunctions(driver, 'testUserR', 'testUserR', 'testUserR', 'testUserR@test.de', 'testuserrpasswort');
    await adminFunctions.createUser();
});

afterEach(async() => {
    await adminFunctions.removeUser();
    await driver.quit();
});


describe('administration rest tests', () => {

    test('rest - user is admin in general = admin in redmine', async() => {
        await adminFunctions.giveAdminRights();
        const apiKey = await adminFunctions.getApiKeyOfTestuser();
        await adminFunctions.accessUsersJson(apiKey, 200);
    });

    test('rest - user is no admin in general = no admin in redmine', async() => {
        const apiKey = await adminFunctions.getApiKeyOfTestuser();
        await adminFunctions.accessUsersJson(apiKey, 403);
    });

    test('rest - user gets admin rights in redmine', async() => {

        await adminFunctions.testuserLogin(); // test user login to update information in redmine
        await adminFunctions.testuserLogout();
        await adminFunctions.giveAdminRightsInRedmine();
        const apiKey = await adminFunctions.getApiKeyOfTestuser();
        await adminFunctions.accessUsersJson(apiKey, 200);
    });

    test('rest - user gets admin rights in redmine and then in usermanagement = take rights in usermanagement', async() => {

        await adminFunctions.testuserLogin(); // test user login to update information in redmine
        await adminFunctions.testuserLogout();
        await adminFunctions.giveAdminRightsInRedmine();
        await adminFunctions.giveAdminRights();
        await adminFunctions.takeAdminRights();
        const apiKey = await adminFunctions.getApiKeyOfTestuser();
        await adminFunctions.accessUsersJson(apiKey, 200);
    });

    test('rest - user gets admin rights in redmine = take rights in redmine', async() => {

        await adminFunctions.testuserLogin(); // test user login to update information in redmine
        await adminFunctions.testuserLogout();
        await adminFunctions.giveAdminRightsInRedmine();
        await adminFunctions.takeAdminRightsInRedmine();
        const apiKey = await adminFunctions.getApiKeyOfTestuser();
        await adminFunctions.accessUsersJson(apiKey, 403);
    });

    test('rest - user gets admin rights in redmine and then in usermanagement = take rights in redmine', async() => {

        await adminFunctions.testuserLogin(); // test user login to update information in redmine
        await adminFunctions.testuserLogout();
        await adminFunctions.giveAdminRightsInRedmine();
        await adminFunctions.giveAdminRights();
        await adminFunctions.takeAdminRightsInRedmine();
        const apiKey = await adminFunctions.getApiKeyOfTestuser();
        await adminFunctions.accessUsersJson(apiKey, 200);
    });

});