const config = require('./config');
const expectations = require('./expectations');
const init = require('./init');

const webdriver = require('selenium-webdriver');
const By = webdriver.By;
const until = webdriver.until;

jest.setTimeout(30000);

let driver;

beforeEach(() => {
    driver = init.setDriver(webdriver);
});

afterEach(() => {
    driver.quit();
});


describe('cas browser tests', () => {

    test('redirect to cas authentication', async() => {
        driver.get(config.baseUrl + config.redmineUrlExtension);
        const url = await driver.getCurrentUrl();

        expectations.expectCasLogin(url);
    });

    test('cas authentication', async() => {
        init.login(driver, By, config.redmineUrlExtension);
        const username = await driver.findElement(By.css('#loggedas a.user')).getText();

        expect(username).toBe(config.username);
    });

    test('check cas attributes', async() => {
        init.login(driver, By, config.redmineUrlExtension);
        driver.findElement(By.css('#account a.my-account')).click();

        const firstname = await driver.findElement(By.id('user_firstname')).getAttribute('value');
        expect(firstname).toBe(config.firstname);

        const lastname = await driver.findElement(By.id('user_lastname')).getAttribute('value');
        expect(lastname).toBe(config.lastname);

        const email = await driver.findElement(By.id('user_mail')).getAttribute('value');
        expect(email).toBe(config.email);
    });

    test('front channel logout', async() => {
        init.login(driver, By, config.redmineUrlExtension);
        driver.findElement(By.css('a.logout')).click();
        const url = await driver.getCurrentUrl();

        expectations.expectCasLogout(url);
    });

    test('back channel logout', async() => {
        init.login(driver, By, config.redmineUrlExtension);
        driver.get(config.baseUrl + '/cas/logout');
        driver.get(config.baseUrl + config.redmineUrlExtension);
        const url = await driver.getCurrentUrl();

        expectations.expectCasLogin(url);
    });

});