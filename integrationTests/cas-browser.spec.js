const config = require('./config');
const expectations = require('./expectations');
const utils = require('./utils');

const webdriver = require('selenium-webdriver');
const By = webdriver.By;
const until = webdriver.until;

jest.setTimeout(30000);

let driver;

beforeEach(async() => {
    driver = utils.createDriver(webdriver);
    await driver.manage().window().maximize();
});

afterEach(async () => {
    await driver.quit();
});


describe('cas browser tests', () => {

    test('redirect to cas authentication', async() => {
        await driver.get(config.baseUrl + config.redmineContextPath);
        const url = await driver.getCurrentUrl();
        expectations.expectCasLogin(url);
    });

    test('cas authentication', async() => {
        await utils.login(driver, config.redmineContextPath);
        await driver.wait(until.elementLocated(By.css('#loggedas a.user')), 5000);
        const username = await driver.findElement(By.css('#loggedas a.user')).getText();
        expect(username).toBe(config.username);
    });

    test('check cas attributes', async() => {
        await utils.login(driver, config.redmineContextPath);
        await driver.wait(until.elementLocated(By.css('#account a.my-account')), 5000);
        await driver.findElement(By.css('#account a.my-account')).click();
        let firstname = await driver.findElement(By.id('user_firstname'));
        firstname = await firstname.getAttribute('value');
        expect(firstname).toBe(config.firstname);

        let lastname = await driver.findElement(By.id('user_lastname'));
        lastname = await lastname.getAttribute('value');
        expect(lastname).toBe(config.lastname);

        let email = await driver.findElement(By.id('user_mail'));
        email = await email.getAttribute('value');
        expect(email).toBe(config.email);
    });

    test('front channel logout', async() => {
        await utils.login(driver, config.redmineContextPath);
        await driver.wait(until.elementLocated(By.css('a.logout')), 5000);
        await driver.findElement(By.css('a.logout')).click();
        const url = await driver.getCurrentUrl();

        expectations.expectCasLogout(url);
    });

    test('back channel logout', async() => {
        await utils.login(driver, config.redmineContextPath);
        await driver.get(config.baseUrl + '/cas/logout');
        await driver.get(config.baseUrl + config.redmineContextPath);
        const url = await driver.getCurrentUrl();
        expectations.expectCasLogin(url);
    });

    test('do not redirect to cas when redirect disabled', async() => {
        await utils.login(driver, config.redmineContextPath + '/cas');
        await utils.setLoginRedirect(driver, false);
        await utils.setAnonymousAccess(driver, true)
        await utils.logout(driver);

        await driver.get(config.baseUrl + config.redmineContextPath + '/login');
        const url = await driver.getCurrentUrl();
        expect(url).toBe(config.baseUrl + config.redmineContextPath + '/login');

        await utils.login(driver, config.redmineContextPath + '/cas');
        await utils.setAnonymousAccess(driver, false)
    });

    test('redirect to cas when redirect enabled', async() => {
        await utils.login(driver, config.redmineContextPath + '/cas');
        await utils.setLoginRedirect(driver, true);
        await utils.setAnonymousAccess(driver, true)
        await utils.logout(driver);

        await driver.get(config.baseUrl + config.redmineContextPath + '/settings/plugin/redmine_cas');
        await driver.get(config.baseUrl + config.redmineContextPath + '/login');
        const url = await driver.getCurrentUrl();
        expect(url).toBe(config.baseUrl + '/cas/login?service=https%3A%2F%2F' + config.fqdn + '%2Fredmine%2F');

        await utils.login(driver, config.redmineContextPath + '/cas');
        await utils.setLoginRedirect(driver, false);
        await utils.setAnonymousAccess(driver, false)
    });
});
