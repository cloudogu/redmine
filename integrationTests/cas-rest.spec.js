const request = require('supertest');
const config = require('./config');
const expectations = require('./expectations');
const utils = require('./utils');

const webdriver = require('selenium-webdriver');
const By = webdriver.By;
const until = webdriver.until;

jest.setTimeout(30000);

// disable certificate validation
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

describe('cas rest tests', () => {

  test('authenticate with basic authentication', async() => {
    await request(config.baseUrl)
      .get(config.redmineContextPath + '/users/current.json')
      .auth(config.username, config.password)
      .expect(200);
  });

  test('authenticate with API key', async() => {
    const driver = await utils.createDriver(webdriver);
    await utils.login(driver, config.redmineContextPath + '/my/api_key');
    await driver.wait(until.elementLocated(By.css('div.box pre')), 5000);
    const apiKey = await driver.findElement(By.css('div.box pre')).getText();

    await request(config.baseUrl)
      .get( config.redmineContextPath + '/users/current.json')
      .set({
        'x-redmine-api-key': apiKey
      })
      .expect(200);
      await driver.quit();
  });

  test('check cas attributes', async() => {
    const response = await request(config.baseUrl)
      .get(config.redmineContextPath + '/users/current.json')
      .auth(config.username, config.password)
      .expect('Content-Type', /json/)
      .expect(200);

    expectations.expectState(response.body);
  });

});