const config = require('./config');
const webdriver = require('selenium-webdriver');
const request = require('supertest');
const utils = require('./utils');
const By = webdriver.By;
const until = webdriver.until;


module.exports = class adminFunctions{

    constructor(driver) {
        this.driver = driver;
    }

    async createUser(){

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

    async removeUser(){

        await request(config.baseUrl)
            .del('/usermgt/api/users/' + config.testuserName)
            .auth(config.username, config.password)
            .expect(204);


        utils.login(this.driver, '/redmine');
        //delete user in redmine
        await this.driver.get(config.baseUrl + '/redmine/users');
        await this.driver.wait(until.elementLocated(By.linkText(config.testuserName)), 5000);
        await this.driver.findElement(By.linkText(config.testuserName)).click();
        await this.driver.findElement(By.css('a.icon.icon-del')).click();
        await this.driver.switchTo().alert().accept();
        await this.driver.wait(until.elementLocated(By.linkText(config.username)));
    }

    async giveAdminRights(){

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

    adminRightsInRedmine(){
        utils.login(this.driver, '/redmine');
        this.driver.get(config.baseUrl + '/redmine/users');

        this.driver.wait(until.elementLocated(By.linkText(config.testuserName)), 5000);
        this.driver.findElement(By.linkText(config.testuserName)).click();
        this.driver.findElement(By.css('input[type="checkbox"]')).click();
        this.driver.findElement(By.css('input[type="submit"]')).click();
        this.driver.findElement(By.css('a.logout')).click();

    }

    async takeAdminRights(){

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

    testuserLogin() {

        this.driver.get(config.baseUrl + '/redmine');
        this.driver.wait(until.elementLocated(By.id('username')), 5000);
        this.driver.findElement(By.id('username')).sendKeys(config.testuserName);
        this.driver.findElement(By.id('password')).sendKeys(config.testuserPasswort);
        this.driver.findElement(By.css('input[name="submit"]')).click();
    };

    async isAdministratorInRedmine(){

        return await this.driver.findElement(webdriver.By.css("a.administration")).then(function() {
            return true;//it was found
        }, function(err) {
            if (err instanceof webdriver.error.NoSuchElementError) {
                return false;//element did not exist
            } else {
                webdriver.promise.rejected(err);//some other error...
            }
        });
    };

}
