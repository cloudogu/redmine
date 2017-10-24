let cesUrl = process.env.CES_URL;
if (!cesUrl) {
  // url from ecosystem with private network
  cesUrl = "https://192.168.42.2"
}

let webdriverType = process.env.WEBDRIVER;
if (!webdriverType) {
  webdriverType = 'local';
}

module.exports = {
    baseUrl: cesUrl,
    redmineContextPath: '/redmine',
    username: 'ces-admin',
    password: 'ecosystem2016',
    firstname: 'admin',
    lastname: 'admin',
    displayName: 'admin',
    email: 'ces-admin@cloudogu.com',
    webdriverType: webdriverType,
    debug: true
  };