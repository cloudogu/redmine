const config = require('./config');
const classAdminFunctions = require('./adminFunctions');
const expectations = require('./expectations');
const utils = require('./utils');
const webdriver = require('selenium-webdriver');
const By = webdriver.By;
const until = webdriver.until;

jest.setTimeout(60000);

let driver;
let adminFunctions;

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

beforeEach(async() => {
    driver = utils.createDriver(webdriver);

    adminFunctions = new classAdminFunctions(driver);
    await adminFunctions.createUser();
});

afterEach(async() => {
    driver.findElement(By.css('a.logout')).click();
    await adminFunctions.removeUser();
    await driver.quit();
});

describe('administration rights', () => {

    test('user is admin in general = admin in redmine', async() => {

        adminFunctions.giveAdminRights();
        adminFunctions.testuserLogin();
        var adminrights = await adminFunctions.isAdministratorInRedmine();
        expect(adminrights).toBe(true);

    });

    test('user is no admin in general = no admin in redmine', async() => {

        adminFunctions.testuserLogin();
        var adminrights = await adminFunctions.isAdministratorInRedmine();
        expect(adminrights).toBe(false);
    });

    test('user gets admin rights in redmine', async() => {

        adminFunctions.testuserLogin(); // test user login to update information in redmine
        driver.wait(until.elementLocated(By.css('a.logout')), 5000);
        driver.findElement(By.css('a.logout')).click();
        await adminFunctions.giveAdminRightsInRedmine();
        adminFunctions.testuserLogin();
        var adminrights = await adminFunctions.isAdministratorInRedmine();
        expect(adminrights).toBe(true);

    });

    test('user gets admin rights in redmine and then in usermanagement = take rights in usermanagement', async() => {

        adminFunctions.testuserLogin(); // test user login to update information in redmine
        driver.wait(until.elementLocated(By.css('a.logout')), 5000);
        driver.findElement(By.css('a.logout')).click();
        await adminFunctions.giveAdminRightsInRedmine();
        adminFunctions.giveAdminRights();
        adminFunctions.takeAdminRights();
        adminFunctions.testuserLogin();
        var adminrights = await adminFunctions.isAdministratorInRedmine();
        expect(adminrights).toBe(true);

    });

    test('user gets admin rights in redmine = take rights in redmine', async() => {

        adminFunctions.testuserLogin(); // test user login to update information in redmine
        driver.wait(until.elementLocated(By.css('a.logout')), 5000);
        driver.findElement(By.css('a.logout')).click();
        await adminFunctions.giveAdminRightsInRedmine();
        await adminFunctions.takeAdminRightsInRedmine(); // takes them here!
        adminFunctions.testuserLogin();
        var adminrights = await adminFunctions.isAdministratorInRedmine();
        expect(adminrights).toBe(false);

    });

    test('user gets admin rights in redmine and then in usermanagement = take rights in redmine', async() => {

        adminFunctions.testuserLogin(); // test user login to update information in redmine
        driver.wait(until.elementLocated(By.css('a.logout')), 5000);
        driver.findElement(By.css('a.logout')).click();
        await adminFunctions.giveAdminRightsInRedmine();
        adminFunctions.giveAdminRights();
        await adminFunctions.takeAdminRightsInRedmine(); // takes them here!
        adminFunctions.testuserLogin();
        var adminrights = await adminFunctions.isAdministratorInRedmine();
        expect(adminrights).toBe(true);

    });


});