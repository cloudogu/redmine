const config = require('./config');

const webdriver = require('selenium-webdriver');
const By = webdriver.By;

exports.createDriver = function(){
    if (config.webdriverType === 'local') {
        return createLocalDriver();
    }
    return createRemoteDriver();
};

function createRemoteDriver() {
    return new webdriver.Builder()
    .build();
}

function createLocalDriver() {
  return new webdriver.Builder()
    .withCapabilities(webdriver.Capabilities.chrome())
    .build();
}

exports.login = function(driver, relativeUrl) {
    driver.get(config.baseUrl + relativeUrl);
    driver.findElement(By.id('username')).sendKeys(config.username);
    driver.findElement(By.id('password')).sendKeys(config.password);
    driver.findElement(By.css('input[name="submit"]')).click();
};