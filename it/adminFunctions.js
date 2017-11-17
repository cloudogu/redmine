const config = require('./config');
const webdriver = require('selenium-webdriver');
const request = require('supertest');
const utils = require('./utils');
const By = webdriver.By;
const until = webdriver.until;


module.exports = class adminFunctions{

    constructor(driver, testuserName, testUserFirstname, testuserSurname, testuserEmail, testuserPasswort) {
        this.driver = driver;
        this.testuserName=testuserName;
        this.testuserFirstname=testUserFirstname;
        this.testuserSurname=testuserSurname;
        this.testuserEmail=testuserEmail;
        this.testuserPasswort=testuserPasswort;
    };

    async createUser(){

        await request(config.baseUrl)
            .post('/usermgt/api/users/')
            .auth(config.username, config.password)

            .set('Content-Type', 'application/json;charset=UTF-8')
            .type('json')
            .send({'memberOf':[],
                'username':this.testuserName,
                'givenname':this.testuserFirstname,
                'surname': this.testuserSurname,
                'displayName':this.testuserName,
                'mail':this.testuserEmail,
                'password':this.testuserPasswort});
          //  .expect(201);
    };

    async removeUser(){

        await request(config.baseUrl)
            .del('/usermgt/api/users/' + this.testuserName)
            .auth(config.username, config.password);
           // .expect(204);


        utils.login(this.driver, '/redmine');
        //delete user in redmine
        await this.driver.get(config.baseUrl + '/redmine/users');
        await this.driver.wait(until.elementLocated(By.linkText(this.testuserName)), 5000);
        await this.driver.findElement(By.linkText(this.testuserName)).click();
        await this.driver.wait(until.elementLocated(By.css('a.icon.icon-del')), 5000);
        await this.driver.findElement(By.css('a.icon.icon-del')).click();
        await this.driver.switchTo().alert().accept();
        await this.driver.wait(until.elementLocated(By.linkText(config.username)));
    };

    async giveAdminRights(){

        await request(config.baseUrl)
            .put('/usermgt/api/users/' + this.testuserName)
            .auth(config.username, config.password)
            .set('Content-Type', 'application/json;charset=UTF-8')
            .type('json')
            .send({'memberOf':[config.adminGroup],
                'username':this.testuserName,
                'givenname':this.testuserFirstname,
                'surname': this.testuserSurname,
                'displayName':this.testuserName,
                'mail':this.testuserEmail,
                'password':this.testuserPasswort})
            .expect(204);
    };

    async giveAdminRightsInRedmine(){
        utils.login(this.driver, '/redmine');
        this.driver.get(config.baseUrl + '/redmine/users');

        this.driver.wait(until.elementLocated(By.linkText(this.testuserName)), 5000);
        this.driver.findElement(By.linkText(this.testuserName)).click();
        this.driver.wait(until.elementLocated(By.css('input[type="checkbox"]')), 5000);
        var buttonEnabled = await this.driver.findElement(By.css('input#user_admin')).isSelected();
        if(!buttonEnabled) this.driver.findElement(By.css('input#user_admin')).click();
        await this.driver.findElement(By.css('input[type="submit"]')).click();
        await this.driver.wait(until.elementLocated(By.css('a.logout')), 5000);
        await this.driver.findElement(By.css('a.logout')).click();



    };

    async takeAdminRightsInRedmine(){
        utils.login(this.driver, '/redmine');
        this.driver.get(config.baseUrl + '/redmine/users');

        this.driver.wait(until.elementLocated(By.linkText(this.testuserName)), 5000);
        this.driver.findElement(By.linkText(this.testuserName)).click();
        this.driver.wait(until.elementLocated(By.css('input#user_admin')), 5000);
        var buttonEnabled = await this.driver.findElement(By.css('input#user_admin')).isSelected();
        if(buttonEnabled) this.driver.findElement(By.css('input#user_admin')).click();
        await this.driver.findElement(By.css('input[type="submit"]')).click();
        await this.driver.wait(until.elementLocated(By.css('a.logout')), 5000);
        await this.driver.findElement(By.css('a.logout')).click();

    };


    async takeAdminRights(){

        await request(config.baseUrl)
            .put('/usermgt/api/users/' + this.testuserName)
            .auth(config.username, config.password)
            .set('Content-Type', 'application/json;charset=UTF-8')
            .type('json')
            .send({'memberOf':[],
                'username':this.testuserName,
                'givenname':this.testuserFirstname,
                'surname': this.testuserSurname,
                'displayName':this.testuserName,
                'mail':this.testuserEmail,
                'password':this.testuserPasswort})
            .expect(204);
    };

    async testuserLogin() {

        this.driver.get(config.baseUrl + '/redmine');
        this.driver.wait(until.elementLocated(By.id('username')), 5000);
        this.driver.findElement(By.id('username')).sendKeys(this.testuserName);
        this.driver.findElement(By.id('password')).sendKeys(this.testuserPasswort);
        this.driver.findElement(By.css('input[name="submit"]')).click();
    };

    async testuserLogout() {
        await this.driver.wait(until.elementLocated(By.css('a.logout')), 5000);
        await this.driver.findElement(By.css('a.logout')).click();
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

    async accessUsersJson(apiKey, expectStatus){

        await request(config.baseUrl)
            .get( config.redmineContextPath + '/users.json')
            .set({
                'X-Redmine-API-Key': apiKey
            })
            .expect(expectStatus); //403 = "Forbidden", 200 = "OK"
    };

    async getApiKeyOfTestuser(){

        this.testuserLogin();
        this.driver.get(config.baseUrl + config.redmineContextPath + '/my/api_key');
        this.driver.wait(until.elementLocated(By.css('div.box pre')), 5000);
        const apiKey = await this.driver.findElement(By.css('div.box pre')).getText();
        await this.testuserLogout();
        return apiKey;
    };

};
