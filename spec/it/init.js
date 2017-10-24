const config = require('./config');

exports.setDriver = function(webdriver){
    return new webdriver.Builder()
    .withCapabilities(webdriver.Capabilities.chrome())
    .build();
};

exports.login = function(driver, By, url) {
    driver.get(config.baseUrl + url);
    driver.findElement(By.id('username')).sendKeys(config.username);
    driver.findElement(By.id('password')).sendKeys(config.password);
    driver.findElement(By.css('input[name="submit"]')).click();
};