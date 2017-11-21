let cesFqdn = process.env.CES_FQDN;
if (!cesFqdn) {
  // url from ecosystem with private network
  cesFqdn = "192.168.115.95"//"192.168.42.2"
}

let webdriverType = process.env.WEBDRIVER;
if (!webdriverType) {
  webdriverType = 'local';
}

module.exports = {
    fqdn: cesFqdn,
    baseUrl: 'https://' + cesFqdn,
    redmineContextPath: '/redmine',
    username: 'admin',//'ces-admin',
    password: 'adminpw',//'ecosystem2016',
    firstname: 'admin',
    lastname: 'admin',
    displayName: 'admin',
    email: 'admin@test.de',//'ces-admin@cloudogu.com',
    webdriverType: webdriverType,
    debug: true,
    adminGroup: 'admin'//'CesAdministrators'
};
