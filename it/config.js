let cesFqdn = process.env.CES_FQDN;
if (!cesFqdn) {
  // url from ecosystem with private network
  cesFqdn = "192.168.42.2"
}

let webdriverType = process.env.WEBDRIVER;
if (!webdriverType) {
  webdriverType = 'local';
}

module.exports = {
    fqdn: cesFqdn,
    baseUrl: 'https://' + cesFqdn,
    redmineContextPath: '/redmine',
    username: 'ces-admin',
    password: 'ecosystem2016',
    firstname: 'admin',
    lastname: 'admin',
    displayName: 'admin',
    email: 'ces-admin@cloudogu.com',
    webdriverType: webdriverType,
    debug: true,
    testuserName:'testUser',
    testuserFirstname: 'testUser',
    testuserSurname: 'testUser',
    testuserEmail: 'testuser@test.de',
    testuserPasswort:'testpassword',
    adminGroup: 'CesAdministrators'
};
