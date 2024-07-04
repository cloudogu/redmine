#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

FROM_VERSION="${1}"
RED=$(printf '\033[0;31m')
COLOR_OFF=$(printf '\033[0m')

# versionXLessOrEqualThanY returns true if X is less than or equal to Y; otherwise false
function versionXLessOrEqualThanY() {
  local sourceVersion="${1}"
  local targetVersion="${2}"

  if [[ "${sourceVersion}" == "${targetVersion}" ]]; then
    echo "upgrade to same version"
    return 0
  fi

  declare -r semVerRegex='([0-9]+)\.([0-9]+)\.([0-9]+)-([0-9]+)'

  sourceMajor=0
  sourceMinor=0
  sourceBugfix=0
  sourceDogu=0
  targetMajor=0
  targetMinor=0
  targetBugfix=0
  targetDogu=0

  if [[ ${sourceVersion} =~ ${semVerRegex} ]]; then
    sourceMajor=${BASH_REMATCH[1]}
    sourceMinor="${BASH_REMATCH[2]}"
    sourceBugfix="${BASH_REMATCH[3]}"
    sourceDogu="${BASH_REMATCH[4]}"
  else
    echo "ERROR: source dogu version ${sourceVersion} does not seem to be a semantic version"
    exit 1
  fi

  if [[ ${targetVersion} =~ ${semVerRegex} ]]; then
    targetMajor=${BASH_REMATCH[1]}
    targetMinor="${BASH_REMATCH[2]}"
    targetBugfix="${BASH_REMATCH[3]}"
    targetDogu="${BASH_REMATCH[4]}"
  else
    echo "ERROR: target dogu version ${targetVersion} does not seem to be a semantic version"
    exit 1
  fi

  if [[ $((sourceMajor)) -lt $((targetMajor)) ]]; then
    return 0
  fi
  if [[ $((sourceMajor)) -le $((targetMajor)) && $((sourceMinor)) -lt $((targetMinor)) ]]; then
    return 0
  fi
  if [[ $((sourceMajor)) -le $((targetMajor)) && $((sourceMinor)) -le $((targetMinor)) && $((sourceBugfix)) -lt $((targetBugfix)) ]]; then
    return 0
  fi
  if [[ $((sourceMajor)) -le $((targetMajor)) && $((sourceMinor)) -le $((targetMinor)) && $((sourceBugfix)) -le $((targetBugfix)) && $((sourceDogu)) -lt $((targetDogu)) ]]; then
    return 0
  fi

  return 1
}

runNotify() {
  echo "Please be aware that after any upgrade of redmine existing session cookies"
  echo "will most likely stop working. If a user tries to access redmine with a"
  echo "pre-upgrade session cookie it may result in an error."

  if versionXLessOrEqualThanY "${FROM_VERSION}" "5.1.3-1"; then
    notifyAboutMarkdownFormatterDeprecation
  fi
}

notifyAboutMarkdownFormatterDeprecation() {
  printf "%s[WARNING]%s\n\n" "${RED}" "${COLOR_OFF}"

  cat <<EOF
Starting with Redmine 5.1.3-1, the previous formatter 'Markdown' is deprecated in favor of the formatter 'CommonMark Markdown (github-flavoured)' which no longer supports underlining (but adds lots of new features). Underlined text will be rendered differently. The deprecated markdown formatter may be removed in future versions."

For more information please see the changelog or release notes.
EOF
}

# make the script only run when executed, not when sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  runNotify "$@"
fi
