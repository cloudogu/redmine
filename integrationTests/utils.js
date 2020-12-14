const config = require('./config');

const webdriver = require('selenium-webdriver');
const By = webdriver.By;

const chromeCapabilities = webdriver.Capabilities.chrome();

const chromeOptions = {
    'args': ['--test-type', '--start-maximized']
};

chromeCapabilities.set('chromeOptions', chromeOptions);
chromeCapabilities.set('name', 'Redmine ITs');
// set filename pattern for zalenium videos
chromeCapabilities.set("testFileNameTemplate", "{testName}_{testStatus}");
chromeCapabilities.set("acceptInsecureCerts", "true");

let driver = null;

const zaleniumReporter = {

    specStarted: function(test) {
        // set testname for zalenium
        chromeCapabilities.set("name", test.fullName);
    },

    // does not work on jasmine 2, we have to wait until jest updates jasmine to v3
    // set status to success or failed, currently all tests have status completed
    xspecDone: function(result, done) {
        driver.manage().addCookie({
            name: "zaleniumTestPassed", 
            value: result.status === "passed"
        });
        driver.quit().then(done);
    }
};

jasmine.getEnv().addReporter(zaleniumReporter);

exports.createDriver = function(){
    if (config.webdriverType === 'local') {
        driver = createLocalDriver();
    } else {
        driver = createRemoteDriver();
    }
    
    return driver;
};

function createRemoteDriver() {
    return new webdriver.Builder().withCapabilities(chromeCapabilities)
    .build();
}

function createLocalDriver() {
  return new webdriver.Builder().withCapabilities(chromeCapabilities)
    .usingServer('http://localhost:4444/wd/hub')
    .build();
}

exports.setLoginRedirect = async function (driver, redirect) {
    await driver.get(config.baseUrl + config.redmineContextPath + '/settings/plugin/redmine_cas');
    try {
        if (redirect) {
            await driver.findElement(By.css('#settings_redirect_enabled:not(:checked)')).click();
        } else {
            await driver.findElement(By.css('#settings_redirect_enabled:checked')).click();
        }
    }
    catch (e){

    }
    await driver.findElement(By.name('commit')).click();
}

exports.setAnonymousAccess = async function (driver, anonymousAccess) {
    await driver.get(config.baseUrl + config.redmineContextPath + '/settings?tab=authentication');

    await driver.wait(webdriver.until.elementLocated(By.id("settings_login_required")), 2000);
    await driver.findElement(By.id("settings_login_required")).click()
    if (anonymousAccess === true) {
        await driver.findElement(By.css("#settings_login_required option[value='0']")).click()
    } else{
        await driver.findElement(By.css("#settings_login_required option[value='1']")).click()
    }
    await driver.findElement(By.css("form[action*='tab=authentication'] input[type='submit']")).click();
}

exports.login = async function(driver, relativeUrl) {
    await driver.get(config.baseUrl + relativeUrl);
    await driver.findElement(By.id('username')).sendKeys(config.username);
    await driver.findElement(By.id('password')).sendKeys(config.password);
    await driver.findElement(By.css('input[name="submit"]')).click();
};

exports.logout = async function(driver) {
    await driver.get(config.baseUrl + '/cas/logout');
};
