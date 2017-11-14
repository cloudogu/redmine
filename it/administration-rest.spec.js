const request = require('supertest');
const config = require('./config');
const classAdminFunctions = require('./adminFunctions');
const utils = require('./utils');
const webdriver = require('selenium-webdriver');
const By = webdriver.By;
const keys = webdriver.Key;
const until = webdriver.until;

jest.setTimeout(30000);
let driver;
let adminFunctions;

// disable certificate validation
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

beforeEach(async() => {
    driver = utils.createDriver(webdriver);
    adminFunctions = new classAdminFunctions(driver);
    await adminFunctions.createUser();
});

afterEach(async() => {
    await adminFunctions.removeUser();
    await driver.quit();
});


describe('administration rest tests', () => {

    test('rest - user is admin in general = admin in redmine', async() => {
        adminFunctions.giveAdminRights();
        const apiKey = await adminFunctions.getApiKeyOfTestuser();

        await adminFunctions.accessUsersJson(apiKey, 200);
    });

    test('rest - user is no admin in general = no admin in redmine', async() => {
        const apiKey = await adminFunctions.getApiKeyOfTestuser();
        await adminFunctions.accessUsersJson(apiKey, 403);
    });

    test('rest - user gets admin rights in redmine', async() => {

        adminFunctions.testuserLogin(); // test user login to update information in redmine
        await adminFunctions.testuserLogout();
        adminFunctions.adminRightsInRedmine();
        const apiKey = await adminFunctions.getApiKeyOfTestuser();

        await adminFunctions.accessUsersJson(apiKey, 200);
    });

    test('rest - user gets admin rights in redmine and then in usermanagement = take rights in usermanagement', async() => {

        //utils.testuserLogin(driver, '/redmine');
        adminFunctions.testuserLogin(); // test user login to update information in redmine
        await adminFunctions.testuserLogout();
        adminFunctions.adminRightsInRedmine();
        adminFunctions.giveAdminRights();
        adminFunctions.takeAdminRights();
        const apiKey = await adminFunctions.getApiKeyOfTestuser();

        await adminFunctions.accessUsersJson(apiKey, 200);
    });

    test('rest - user gets admin rights in redmine = take rights in redmine', async() => {

        adminFunctions.testuserLogin(); // test user login to update information in redmine
        await adminFunctions.testuserLogout();
        adminFunctions.adminRightsInRedmine();
        adminFunctions.adminRightsInRedmine(); // takes them here!
        const apiKey = await adminFunctions.getApiKeyOfTestuser();

        await adminFunctions.accessUsersJson(apiKey, 403);
    });

    test('rest - user gets admin rights in redmine and then in usermanagement = take rights in redmine', async() => {

        adminFunctions.testuserLogin(); // test user login to update information in redmine
        await adminFunctions.testuserLogout();
        adminFunctions.adminRightsInRedmine();
        adminFunctions.giveAdminRights();
        adminFunctions.adminRightsInRedmine(); // takes them here!
        const apiKey = await adminFunctions.getApiKeyOfTestuser();

        await adminFunctions.accessUsersJson(apiKey, 200);
    });

});