const config = require('./config');
const expectations = require('./expectations');
const utils = require('./utils');

const webdriver = require('selenium-webdriver');
const keys = webdriver.Key;
const By = webdriver.By;
const until = webdriver.until;

jest.setTimeout(30000);

let driver;

beforeEach(async() => {
    driver = new webdriver.Builder()
        .withCapabilities(webdriver.Capabilities.chrome())
        .build();
    createUser();
    await driver.findElement(By.id('msg'));
});

afterEach(async() => {
    driver.findElement(By.css('a.logout')).click();
    removeUser();
    await driver.quit();
});

function loginToUsermanagementUsers(){
    utils.login(driver, '/usermgt');
    driver.get(config.baseUrl + '/usermgt/#/users');
}

function logoutOfUsermanagement(){
    driver.wait(until.elementLocated(By.css('a[href="api/logout"]')), 5000);
    driver.findElement(By.css('a[href="api/logout"]')).click();
}

function createUser(){
    loginToUsermanagementUsers();
    driver.wait(until.elementLocated(By.css('a.btn.btn-default.pull-right')), 5000);
    driver.findElement(By.css('a.btn.btn-default.pull-right')).click();

    driver.findElement(By.id('username')).sendKeys(config.testuserName);
    driver.findElement(By.id('givenname')).sendKeys(config.testuserFirstname);
    driver.findElement(By.id('surname')).sendKeys(config.testuserSurname);
    driver.findElement(By.id('displayName')).sendKeys(config.testuserName);
    driver.findElement(By.id('email')).sendKeys(config.testuserEmail);
    driver.findElement(By.id('password')).sendKeys(config.testuserPasswort);
    driver.findElement(By.id('confirmPassword')).sendKeys(config.testuserPasswort);

    driver.findElement(By.css('button[type="submit"]')).click();
    logoutOfUsermanagement();

}

async function removeUser(){
    loginToUsermanagementUsers();

    //delete user in user management
    driver.wait(until.elementLocated(By.css('a[href="#/user/' + config.testuserName + '"]')), 5000);
    driver.findElement(By.css('a[href="#/user/' + config.testuserName + '"]')).click();
    driver.wait(until.elementLocated(By.css('button[ng-click="remove(user)"')), 5000);
    driver.findElement(By.css('button[ng-click="remove(user)"')).click();
    driver.wait(until.elementLocated(By.css('button.btn.btn-danger')), 5000);
    driver.findElement(By.css('button.btn.btn-danger')).click();

    //delete user in redmine
    driver.get(config.baseUrl + '/redmine/users');
    driver.wait(until.elementLocated(By.linkText(config.testuserName)), 5000);
    driver.findElement(By.linkText(config.testuserName)).click();
    driver.findElement(By.css('a.icon.icon-del')).click();
    driver.switchTo().alert().accept();
    driver.wait(until.elementLocated(By.linkText('admin')));
}

function giveAdminRights(){
    loginToUsermanagementUsers();
    driver.wait(until.elementLocated(By.css('a[href="#/user/' + config.testuserName + '"]')), 5000);
    driver.findElement(By.css('a[href="#/user/' + config.testuserName + '"]')).click();
    driver.wait(until.elementLocated(By.css('li[heading="Groups"] a.ng-binding')), 5000);
    driver.findElement(By.css('li[heading="Groups"] a.ng-binding')).click();
    driver.findElement(By.id('addGroup')).sendKeys('admin', keys.ENTER);
    driver.wait(until.elementLocated(By.css('li[heading="Options"] a.ng-binding')), 5000);
    driver.findElement(By.css('li[heading="Options"] a.ng-binding')).click();
    driver.findElement(By.css('button[type="submit"]')).click();
    logoutOfUsermanagement();
}

function adminRightsInRedmine(){
    loginToUsermanagementUsers();
    driver.get(config.baseUrl + '/redmine/users');

    driver.wait(until.elementLocated(By.linkText(config.testuserName)), 5000);
    driver.findElement(By.linkText(config.testuserName)).click();
    driver.findElement(By.css('input[type="checkbox"]')).click();
    driver.findElement(By.css('input[type="submit"]')).click();
    driver.findElement(By.css('a.logout')).click();

}

function takeAdminRights(){
    loginToUsermanagementUsers();
    driver.wait(until.elementLocated(By.css('a[href="#/user/' + config.testuserName + '"]')), 5000);
    driver.findElement(By.css('a[href="#/user/' + config.testuserName + '"]')).click();
    driver.wait(until.elementLocated(By.css('li[heading="Groups"] a.ng-binding')), 5000);
    driver.findElement(By.css('li[heading="Groups"] a.ng-binding')).click();
    driver.findElement(By.css('span.glyphicon.glyphicon-remove.remove')).click();
    logoutOfUsermanagement();
}

function testuserLogin() {
    driver.get(config.baseUrl + '/redmine');
    driver.findElement(By.id('username')).sendKeys(config.testuserName);
    driver.findElement(By.id('password')).sendKeys(config.testuserPasswort);
    driver.findElement(By.css('input[name="submit"]')).click();
};

async function isAdministratorInRedmine(){
    return await driver.findElement(webdriver.By.css("a.administration")).then(function() {
        return true;//it was found
    }, function(err) {
        if (err instanceof webdriver.error.NoSuchElementError) {
            return false;//element did not exist
        } else {
            webdriver.promise.rejected(err);//some other error...
        }
    });
};

describe('administration rights', () => {

    test('user is admin in general = admin in redmine', async() => {

        giveAdminRights();
        testuserLogin();
        var adminrights = await isAdministratorInRedmine();
        expect(adminrights).toBe(true);

    });

    test('user is no admin in general = no admin in redmine', async() => {

        testuserLogin();
        var adminrights = await isAdministratorInRedmine();
        expect(adminrights).toBe(false);
    });

    test('user gets admin rights in redmine', async() => {

        testuserLogin(); // test user login to update information in redmine
        driver.findElement(By.css('a.logout')).click();
        adminRightsInRedmine();
        testuserLogin();
        var adminrights = await isAdministratorInRedmine();
        expect(adminrights).toBe(true);

    });

    test('user gets admin rights in redmine and then in usermanagement = take rights in usermanagement', async() => {

        testuserLogin(); // test user login to update information in redmine
        driver.findElement(By.css('a.logout')).click();
        adminRightsInRedmine();
        giveAdminRights();
        takeAdminRights();
        testuserLogin();
        var adminrights = await isAdministratorInRedmine();
        expect(adminrights).toBe(true);

    });

    test('user gets admin rights in redmine = take rights in redmine', async() => {

        testuserLogin(); // test user login to update information in redmine
        driver.findElement(By.css('a.logout')).click();
        adminRightsInRedmine();
        adminRightsInRedmine(); // takes them here!
        testuserLogin();
        var adminrights = await isAdministratorInRedmine();
        expect(adminrights).toBe(false);

    });

    test('user gets admin rights in redmine and then in usermanagement = take rights in redmine', async() => {

        testuserLogin(); // test user login to update information in redmine
        driver.findElement(By.css('a.logout')).click();
        adminRightsInRedmine();
        giveAdminRights();
        adminRightsInRedmine(); // takes them here!
        testuserLogin();
        var adminrights = await isAdministratorInRedmine();
        expect(adminrights).toBe(true);

    });


});