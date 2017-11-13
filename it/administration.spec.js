const config = require('./config');
const expectations = require('./expectations');
const utils = require('./utils');
const request = require('supertest');
const webdriver = require('selenium-webdriver');
const keys = webdriver.Key;
const By = webdriver.By;
const until = webdriver.until;

jest.setTimeout(60000);

let driver;
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';
beforeEach(async() => {
    driver = utils.createDriver(webdriver);
    await createUser();
});

afterEach(async() => {
    driver.findElement(By.css('a.logout')).click();
    await removeUser();
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

async function createUser(){

    await request(config.baseUrl)
        .post('/usermgt/api/users/')
        .auth(config.username, config.password)

        .set('Content-Type', 'application/json;charset=UTF-8')
        .type('json')
        .send({'memberOf':[],
            'username':config.testuserName,
            'givenname':config.testuserFirstname,
            'surname': config.testuserSurname,
            'displayName':config.testuserName,
            'mail':config.testuserEmail,
            'password':config.testuserPasswort})
        .expect(201);
}

async function removeUser(){

    await request(config.baseUrl)
        .del('/usermgt/api/users/' + config.testuserName)
        .auth(config.username, config.password)
        .expect(204);


    loginToUsermanagementUsers();
    //delete user in redmine
    await driver.get(config.baseUrl + '/redmine/users');
    await driver.wait(until.elementLocated(By.linkText(config.testuserName)), 5000);
    await driver.findElement(By.linkText(config.testuserName)).click();
    await driver.findElement(By.css('a.icon.icon-del')).click();
    await driver.switchTo().alert().accept();
    await driver.wait(until.elementLocated(By.linkText('admin')));
}

async function giveAdminRights(){

    await request(config.baseUrl)
        .put('/usermgt/api/users/' + config.testuserName)
        .auth(config.username, config.password)
        .set('Content-Type', 'application/json;charset=UTF-8')
        .type('json')
        .send({'memberOf':[config.adminGroup],
            'username':config.testuserName,
            'givenname':config.testuserFirstname,
            'surname': config.testuserSurname,
            'displayName':config.testuserName,
            'mail':config.testuserEmail,
            'password':config.testuserPasswort})
        .expect(204);
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

async function takeAdminRights(){

    await request(config.baseUrl)
        .put('/usermgt/api/users/' + config.testuserName)
        .auth(config.username, config.password)
        .set('Content-Type', 'application/json;charset=UTF-8')
        .type('json')
        .send({'memberOf':[],
            'username':config.testuserName,
            'givenname':config.testuserFirstname,
            'surname': config.testuserSurname,
            'displayName':config.testuserName,
            'mail':config.testuserEmail,
            'password':config.testuserPasswort})
        .expect(204);
}

function testuserLogin() {
    driver.get(config.baseUrl + '/redmine');
    driver.wait(until.elementLocated(By.id('username')), 5000);
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
        driver.wait(until.elementLocated(By.css('a.logout')), 5000);
        driver.findElement(By.css('a.logout')).click();
        adminRightsInRedmine();
        testuserLogin();
        var adminrights = await isAdministratorInRedmine();
        expect(adminrights).toBe(true);

    });

    test('user gets admin rights in redmine and then in usermanagement = take rights in usermanagement', async() => {

        testuserLogin(); // test user login to update information in redmine
        driver.wait(until.elementLocated(By.css('a.logout')), 5000);
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
        driver.wait(until.elementLocated(By.css('a.logout')), 5000);
        driver.findElement(By.css('a.logout')).click();
        adminRightsInRedmine();
        adminRightsInRedmine(); // takes them here!
        testuserLogin();
        var adminrights = await isAdministratorInRedmine();
        expect(adminrights).toBe(false);

    });

    test('user gets admin rights in redmine and then in usermanagement = take rights in redmine', async() => {

        testuserLogin(); // test user login to update information in redmine
        driver.wait(until.elementLocated(By.css('a.logout')), 5000);
        driver.findElement(By.css('a.logout')).click();
        adminRightsInRedmine();
        giveAdminRights();
        adminRightsInRedmine(); // takes them here!
        testuserLogin();
        var adminrights = await isAdministratorInRedmine();
        expect(adminrights).toBe(true);

    });


});