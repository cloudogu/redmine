# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Changed
- Upgrade to Redmine 4.0.5
- Switch from WEBrick to Puma web server
- Update [redmine_cas plugin](https://github.com/cloudogu/redmine_cas) to v1.2.14
- Update [redmine_activerecord_session_store plugin](https://github.com/cloudogu/redmine_activerecord_session_store) to v0.1.0
- Update [rubycas-client plugin](https://github.com/cloudogu/rubycas-client) to v2.3.15

## Removed
- Gem activerecord-deprecated_finders was removed as it is not maintained in Rails 5 any more. See https://github.com/rails/activerecord-deprecated_finders

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