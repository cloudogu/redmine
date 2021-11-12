# Redmine Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- allow plugin deletion without direct container interaction (#68)

## [v4.2.2-1] - 2021-10-11
### Changed
- Upgrade Redmine to 4.2.2; #66
- Upgrade base image to 3.14.2-2

## [v4.2.1-3] - 2021-09-08
### Changed
- update version of CAS plugin to 1.4.6 #63

## [v4.2.1-2] - 2021-07-30
### Changed
- update version of CAS plugin to 1.4.4 #61

### Added
- Add RAILS_RELATIVE_URL_ROOT environment variable to startup.sh

## [v4.2.1-1] - 2021-06-28
### Changed
- Upgrade redmine to 4.2.1; #59

## [v4.2.0-2] - 2021-06-04
### Changed
- updated the import of the default-config mechanism (#57)

## [v4.2.0-1] - 2021-04-22

### Added
- Mechanism to apply configuration at dogu startup via etcd (#49); See [docs](https://github.com/cloudogu/redmine/blob/develop/docs/operations/default_configuration_de.md)

### Changed
- install `redmine_extended_rest_api` plugin during docker build (#47)
- update deprecated bundle install call (#34)
- Upgrade base image to [3.12.4-1](https://github.com/cloudogu/base/releases/tag/3.12.4-1); #50
- Upgrade Redmine to 4.2.0; #50
- Upgrade Cas Plugin to version 1.3.1; #50
- Switched the integration tests to Cypress; #50

## [v4.1.1-2] - 2021-01-06
### Added
- Added the ability to configure the memory limits with cesapp edit-config; #45

### Changed
- Update dogu-build-lib to `v1.1.1`
- Update zalenium-build-lib to `v2.1.0`
- toggle video recording with build parameter (#76)

## [v4.1.1-1] - 2020-11-19
### Changed
- Upgrade to Redmine 4.1.1; #38
- Upgrade to base image v3.11.6-3
- Update cas plugin to 1.2.15
- Use setup_done flag to check if first or subsequent start
- Remove redundant settings in pre-upgrade #42

### Added
- Add automated dogu release process
- Add dogu upgrade test in Jenkins pipeline
- Add log level adjustment option

## [4.1.0-3](https://github.com/cloudogu/redmine/releases/tag/v4.1.0-3) - 2020-03-20
### Changed
- Update theme to v2.9.1-1 (#36) which applies also diverse style fixes (#36)

### Fixed
- Fixes a checkbox unavailability when an administrator wants to set the user's project roles. (#36) 

## [v4.1.0-2](https://github.com/cloudogu/redmine/releases/tag/v4.1.0-2) - 2020-01-15
### Added
- Add an upgrade notification for invalid cookies after dogu upgrade
- Update theme to v2.8.0-2

## [v4.1.0-1](https://github.com/cloudogu/redmine/releases/tag/v4.1.0-1) - 2020-01-14
### Changed
- Upgrade to Redmine 4.1.0 (#30)
- Add context path to hostname in order to create correct external links (#26)  

## [v4.0.5-1] - 2019-12-02
### Changed
- Upgrade to Redmine 4.0.5
- Switch from WEBrick to Puma web server
- Update [redmine_cas plugin](https://github.com/cloudogu/redmine_cas) to v1.2.14
- Update [redmine_activerecord_session_store plugin](https://github.com/cloudogu/redmine_activerecord_session_store) to v0.1.0
- Update [rubycas-client plugin](https://github.com/cloudogu/rubycas-client) to v2.3.15

### Removed
- Gem activerecord-deprecated_finders was removed as it is not maintained in Rails 5 any more.

## [v3.4.11-1] - 2019-09-04
### Changed
- Update to Redmine 3.4.11

## [v3.4.10-2] - 2019-05-27
### Fixed
- Fix bug "Thumbnails not visible any more" #20

## [v3.4.10-1] - 2019-05-23
### Changed
- Upgrade to Redmine 3.4.10

## [v3.4.8-2] - 2019-01-30
### Fixed
- Fix glitch during the release of v3.4.8-1

## [v3.4.8-1] - 2019-01-30
### Changed
- Upgrade to Redmine 3.4.8

## [v3.4.2-6] - 2018-11-16
### Added
- Introduces the NeedsBackup flag:
    - included volumes: plugins, volumes
    - not included volumes: logs

## [v3.4.2-5] - 2018-05-27
### Added
- Add option for configurable mail address #9

## [v3.4.2-4] - 2017-11-30
### Fixed
- Completes fix for bug regarding links to issues in generated mails #3

## [v3.4.2-3] - 2017-11-23
### Fixed
- Fix for bug regarding links to issues in generated mails #3

## [v3.4.2-2] - 2017-09-28
### Changed
- Update cas plugin to 1.2.13

## [v3.4.2-1] - 2017-08-08
### Changed
- improve installation of core plugins
    - Core plugins are now backed into the image and only manual installed plugins are installed durring startup.

## [v3.3.2-4] - 2017-08-03
### Changed
- enabled gravatar and markdown by default
- improve plugin and theme installation

### Fixed
- fix wrong url in notifications
- fix group synchronization on api login
