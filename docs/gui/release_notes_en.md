# Release Notes

Below you will find the release notes for the Redmine Dogu. 

Technical details on a release can be found in the corresponding [Changelog](https://docs.cloudogu.com/en/docs/dogus/redmine/CHANGELOG/).

## [Unreleased]
* Configuration keys of the ecosystem which handle global password policies are also applied to redmine.
  * This means that the same password policies set in blueprints are also taking effect in redmine.

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