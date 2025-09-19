# Release Notes

Below you will find the release notes for the Redmine Dogu. 

Technical details on a release can be found in the corresponding [Changelog](https://docs.cloudogu.com/en/docs/dogus/redmine/CHANGELOG/).

## [Unreleased]

## [v6.0.6-2] - 2025-09-19
### Changed
* We have only made technical changes. You can find more details in the changelogs.

## [v6.0.6-1] - 2025-08-22
### Changed
* The dogu now offers Redmine version 6.0.6. You can find the Redmine release notes [here](https://www.redmine.org/projects/redmine/wiki/Changelog_6_0#606-2025-07-07)

## [v5.1.8-3] - 2025-08-06
### Changed
* We have only made technical changes. You can find more details in the changelogs.

## [v5.1.8-2] - 2025-06-11
### Added 
*  Added additional config parameters rack/params_limit and rack/bytesize_limit.
* ``rack/params_limit`` increases the limit of parameters in requests to Redmine
  * Attention: Requests with a large number of parameters can take a very long time. During this time, the function of the Redmine dogu is restricted for all users.
* ``rack/bytesize_limit`` increases the limit of parameters in requests to Redmine
  * Attention: Large requests can take a very long time. During this time, the function of the Redmine dogu is restricted for all users.

## [v5.1.8-1] - 2025-05-13
### Changed
* The dogu now offers Redmine version 5.1.8. You can find the Redmine release notes [here](https://www.redmine.org/projects/redmine/wiki/Changelog_5_1)

## [v5.1.6-3] - 2025-04-28
### Changed
- Usage of memory and CPU was optimized for the Kubernetes Mutlinode environment.

## [v5.1.6-2] - 2025-04-04
* We have only made technical changes. You can find more details in the changelogs.

## [v5.1.6-1] - 2025-02-17
* The dogu now offers Redmine version 5.1.6. You can find the Redmine release notes [here](https://www.redmine.org/projects/redmine/wiki/Changelog_5_1#516-2025-01-29).
* This version ensures multinode compatibility by avoiding deletion of the "default_data" configuration key. You can find more details in the changelogs.

## [v5.1.4-3] - 2025-02-17
* the version 5.1.6-1 was released under a wrong version. This version was withdrawn and re-released under the now correct version.

## [v5.1.4-2] - 2025-01-09
* Configuration keys of the ecosystem which handle global password policies are also applied to Redmine.
  * This means that the same password policies that apply to CES users will also apply to internal Redmine users.

## [v5.1.4-1] - 2024-12-16
* The Dogu now offers the Redmine version 5.1.4. The release notes of Redmine can be found [here](https://www.redmine.org/projects/redmine/wiki/Changelog_5_1#514-2024-11-03).

## 5.1.3-4
We have only made technical changes. You can find more details in the changelogs.

## 5.1.3-3
* Cloudogu's own sources are relicensed from MIT to the AGPL 3.0-only.

## 5.1.3-2
* Fix of critical CVE-2024-41110 in library dependencies. This vulnerability could not be actively exploited, though.

## 5.1.3-1

* The Dogu now offers the Redmine version 5.1.2. The Redmine release notes can be found [here](https://www.redmine.org/projects/redmine/wiki/Changelog_5_1#512-2024-06-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX_REPLACE_ME).
* This version deprecates the original Markdown format "Markdown" in favor of the more common Markdown format "CommonMark Markdown (Github-flavored)".
   - For new installations, `CommonMark Markdown (github-flavoured)` is now the default formatter
   - Although the old formatter can still be used, administrators of previous Redmine versions should be prepared to change their projects:
      - Underlined text (`_underline_`) is no longer supported as such and will be displayed _italicized_ instead
      - The [Github documentation](https://docs.github.com/de/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax) has information on most of the supported _Github-flavored Markdown_ formatting (the one in Redmine does not use the latest formatting such as _Alerts_)
   - Other formatters are not affected by this change

## 5.0.8-1

* The Dogu now offers the Redmine version 5.0.8. The release notes of Redmine can be found [here](https://www.redmine.org/projects/redmine/wiki/Changelog_5_0#508-2024-03-04).
* In the past it happened that [changes from the user management](https://docs.cloudogu.com/en/usermanual/usermgt/documentation/#synchronization-of-accounts-and-groups) were not updated in Redmine after a login of the affected user. The bug has been fixed in this version.