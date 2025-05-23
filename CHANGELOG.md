# Redmine Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [v5.1.8-1] - 2025-05-13
### Changed
- [#151] Update Redmine to version 5.1.8

## [v5.1.6-3] - 2025-04-28
### Changed
- [#149] Set sensible resource requests and limits
- [#147] Update Makefiles to 9.9.1
- [#147] Update ces-build-lib to 4.2.0
- [#147] Update dogu-build-lib to 3.2.0

## [v5.1.6-2] - 2025-04-04
### Fixed
- [#145] Fix errors on startup with helpdesk-plugin on multinode

## [v5.1.6-1] - 2025-02-17
### Changed
- [#143] Update Redmine to version 5.1.6
- [#143] change default data import routing to avoid error in Multinode CES environment
- the key `default_data/new_configuration` will no longer be deleted.
  Still, measures are taken to keep imports at a minimum.

## [v5.1.4-3] - 2025-02-17
- this version was retracted

## [v5.1.4-2] - 2025-01-09
### Added
- [#141] configuration keys used for cas password-policies are also applied to redmine

## [v5.1.4-1] - 2024-12-16
- [#138] Update Redmine to version 5.1.4

## [v5.1.3-4] - 2024-09-25
### Changed
- Switch to new CAS service account structure in dogu.json
- [#128] Move state that should be persistent between restarts to local config.

## [v5.1.3-3] - 2024-09-06
### Changed
- Relicense to AGPL-3.0-only

## [v5.1.3-2] - 2024-08-13
### Changed
- [#133] Update base image to 3.19.3-1

### Security
- [#133] close CVE-2024-41110

## [v5.1.3-1] - 2024-07-04
### Changed
- Update Redmine to version 5.1.3 (#130)
  - Redmine 5.1.2 deprecates the previous `Markdown` formatter in favor of the `CommonMark Markdown (github-flavoured)` formatter
    - For new instances the `CommonMark Markdown (github-flavoured)` formatter will be the default
    - The deprecated formatter is still available but may be removed in future versions
    - Administrators of previous Redmine versions should prepare for the up-coming change as the new formatter will introduce some slight changes:
      - Underlined text with `_underline_` is no longer supported and will be rendered as *italic*
      - Mixed lists (ordered and unordered in the same level) will render as two separate lists
      - You can learn more about Github-flavored Markdown in the [Github documentation](https://docs.github.com/de/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax) (not all markups are supported though)
    - Other formatters are not affected by this
- Update base image to Alpine 3.19.2 including doguctl v0.11.0

## [v5.0.8-1] - 2024-03-07
### Changed
- Update Redmine to version 5.0.8
- Update CAS plugin to version 2.1.2
  - This will fix a bug where the user data was not updated on login (#126)
  - This will also fix an error response when a ticket parameter inside an HTTP POST body was mistaken to be a CAS service ticket parameter

## [v5.0.5-4] - 2024-01-24
### Fixed
- Add bigdecimal bundle as a dependency of the `helpdesk` plugin

## [v5.0.5-3] - 2024-01-17
### Fixed
- [#123] Add gem `bigdecimal` because some plugins like `helpdesk` need the dependency on `bundle install` if redmine is starting up.

## [v5.0.5-2] - 2023-10-20
### Fixed
- [#121] FIXED CVE: CVE-2023-4863 CVE-2023-38039 CVE-2023-38545 CVE-2023-39417 CVE-2023-44487

## [v5.0.5-1] - 2023-07-31
### Changed
- Update Redmine to 5.0.5 (#117)
- Clear sessions on each restart of the container
- Update makefiles
- Update redmine_cas plugin
- Update activerecord-session_store plugin
- Update installed version of rubycas-client

### Fixed
- Fix integration tests by upgrading cypress and integration-tests-lib

## [v4.2.9-4] - 2023-05-24
### Changed
- Use custom email domain for the temporary admin user if the constraint is configured in Redmine (#115)

## [v4.2.9-3] - 2023-05-08
### Added
- Trivy image scan during jenkins build (#113)
- Link checker step during jenkins build to verify links inside the markdown documents (#113)

### Changed
- Update makefiles to 7.5.0 (#113)
- Update build libs (#113)

## [v4.2.9-2] - 2023-02-21
### Changed
- Extract admin creation and deletion scripts (#111)

## [v4.2.9-1] - 2023-02-14
### Changed
- Upgrade to Redmine 4.2.9; #109

## [v4.2.8-2] - 2022-10-13
### Changed
- Update PurpleMine theme to version `2.15.0-2` (#107)

## [v4.2.8-1] - 2022-10-06
### Changed
- Upgrade to Redmine 4.2.8; #105
- Upgrade makefiles to version `7.0.1`; #105
- Upgrade makefiles to ces-build-lib `1.57.0`; #105
- Upgrade makefiles to dogu-build-lib `1.6.0`; #105

### Fixed
- Redmine plugins are not saved in the backup. This behaviour is invalid and was reversed; #105

## [v4.2.7-1] - 2022-09-30
### Changed
- Upgrade to Redmine 4.2.7; #103

### Fixed
- Randomized admin password now always contains a special character, an uppercase letter and a number (#99)

## [v4.2.5-2] - 2022-09-23
### Changed
- Update PurpleMine theme (#100)

## [v4.2.5-1] - 2022-05-06
### Fixed
- CVE 2022-21381 by updating Redmine to version 4.2.5 (#95)

### Fixed
- Import of custom configuration fails if local users were not allowed

## [v4.2.3-10] - 2022-04-05
### Fixed
- Fix zlib CVE-2018-25032 by upgrading to version 1.2.12-r0 from Alpine 3.14 #96

## [v4.2.3-9] - 2022-03-11
### Changed
- Gravatar will not be used by default any longer. The admin needs to configure it manually. (#92)

## [v4.2.3-8] - 2022-02-15
### Changed
- Upgrade cas plugin to version 2.0.0 (#88)
- Remove sql-statements to initialize the cas plugin and use the new rake tasks instead (#88)

## [v4.2.3-7] - 2022-02-07
### Changed
- Upgrade to base image 3.14.3-1

## [v4.2.3-6] - 2022-02-01
### Fixed
- Upgrade from dogu version above 4.2.2-1 failed if no additional plugins were installed (#86)

## [v4.2.3-5] - 2022-02-01
### Added
- Add an exposed command to delete a Redmine plugin. Call via the cesapp: 
`cesapp command redmine delete-plugin <plugin-name> --force` (#80)

### Fixed
- plugins can now be installed on first Dogu start. This was prevented by missing dependencies in older versions.

## [v4.2.3-4] - 2022-01-14
### Changed
- Update cas plugin to version 1.5.2 (#84)

## [v4.2.3-3] - 2022-01-12
### Fixed
- Fix missing PostgreSQL credentials which crashes during upgrading (#79)
  - the original defect was introduced with Redmine v4.2.2-3
- Fix semantic version bug which crashes during upgrading (#82)
  - the defect concerns Redmine versions <= v4.1.0-3
  - the defect does not concern Redmine versions >= v4.1.1-1
 
## [v4.2.3-2] - 2022-01-06
### Changed
- Update redmine_cas plugin to version 1.5.1 (#76)

### Fixed
- Fix defect which prevents updating bundled Redmine plugins (#78)

## [v4.2.3-1] - 2021-12-13
### Changed
- Upgrade to Redmine 4.2.3; #69
- Upgrade to dogu-build-lib v1.5.1
- Upgrade dogu-integration-test-library to v2.0.0
- Upgrade cypress to v8.7.0

## [v4.2.2-4] - 2021-12-06
### Changed
- Update rest api plugin to v1.1.0
- Update documentation for default config mechanism
- Make default config mechanism use new features from rest api plugin v1.1.0

## [v4.2.2-3] - 2021-12-06
### Changed
- Install missing plugin gems in post-upgrade (#71)
  - moved install_plugins function from startup.sh to util.sh

## [v4.2.2-2] - 2021-12-01

If you have installed additional plugins to Redmine, please skip this version and upgrade to v4.2.2-3 instead!

### Added
- Allow plugin deletion without direct container interaction (#68)
  - see also [the docs](docs/operations/redmine_plugins_en.md)
- Add new plugin volume `plugins_prod` for direct plugin interaction (#68)
- Add Shell unit tests

### Removed
- Deprecated the volume for plugin provisioning `plugins` (#68)
  - see also [the docs](docs/operations/redmine_plugins_en.md)

### Changed
- Update image maintainer address
- Switch to dogu.json v2 syntax which allows for fine-grained dependency management

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
