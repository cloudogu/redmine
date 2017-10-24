const config = require('./config');

exports.expectState = function(state) {
  const user = state.user;
  expect(user.login).toBe(config.username);
  expect(user.firstname).toBe(config.firstname);
  expect(user.lastname).toBe(config.lastname);
  expect(user.mail).toBe(config.email);

}

exports.expectCasLogin = function(url) {
  expect(url).toBe(config.baseUrl + '/cas/login?service=https%3A%2F%2Fdemo.cloudogu.com%2Fredmine%2Fcas%3Fref%3D%252Fredmine');
}

exports.expectCasLogout = function(url) {
  expect(url).toBe(config.baseUrl + '/cas/logout?destination=https%3A%2F%2Fdemo.cloudogu.com%2Fredmine&gateway=true');
}
