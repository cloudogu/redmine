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

    const driver = utils.createDriver(webdriver);
    utils.login(driver, config.redmineContextPath + '/my/api_key');
    const apiKey = await driver.findElement(By.css('div.box pre')).getText();
    driver.quit();

    await request(config.baseUrl)
      .get( config.redmineContextPath + '/users/current.json')
      .set({
        'X-Redmine-API-Key': apiKey
      })
      .expect(200);
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