const config = require('./config');

const webdriver = require('selenium-webdriver');
const By = webdriver.By;

const chromeCapabilities = webdriver.Capabilities.chrome();

const chromeOptions = {
    'args': ['--test-type', '--start-maximized']
};

chromeCapabilities.set('chromeOptions', chromeOptions);
chromeCapabilities.set('name', 'Redmine ITs');

exports.createDriver = function(){
    if (config.webdriverType === 'local') {
        return createLocalDriver();
    }
    return createRemoteDriver();
};

function createRemoteDriver() {
    return new webdriver.Builder().withCapabilities(webdriver.Capabilities.chrome())
    .build();
}

function createLocalDriver() {
  return new webdriver.Builder().withCapabilities(webdriver.Capabilities.chrome())
    .usingServer('http://localhost:4444/wd/hub')
    .build();
}

exports.login = async function(driver, relativeUrl) {
    await driver.get(config.baseUrl + relativeUrl);
    await driver.findElement(By.id('username')).sendKeys(config.username);
    await driver.findElement(By.id('password')).sendKeys(config.password);
    await driver.findElement(By.css('input[name="submit"]')).click();
};
