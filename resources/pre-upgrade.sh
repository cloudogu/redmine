#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# WORKDIR is a Dockerfile global variable
REDMINE_WORK_DIR="${WORKDIR}"
MIGRATION_TMP_DIR="/var/tmp/redmine/plugins/migration4.4.2.1"
ERROR_SLEEP_IN_S=300

function run_preupgrade() {
  FROM_VERSION="${1}"
  TO_VERSION="${2}"

  echo "Executing Redmine pre-upgrade from ${FROM_VERSION} to ${TO_VERSION}"

  if [ "${FROM_VERSION}" = "${TO_VERSION}" ]; then
    echo "FROM and TO versions are the same; Exiting..."
    exit 0
  fi

  echo "Set registry flag so startup script waits for post-upgrade to finish..."
  doguctl state "upgrading"

  if versionXLessOrEqualThanY "${FROM_VERSION}" "4.2.2-1" ; then
    movePluginsToTempDir
  fi

  doguctl config "startup/setup_done" "true"

  echo "Redmine pre-upgrade done"
}

function movePluginsToTempDir() {
  echo "Move plugins to temporary directory..."

  mkdir -p "${MIGRATION_TMP_DIR}"
  find "${REDMINE_WORK_DIR}"/plugins/* -maxdepth 0 -type d -exec mv '{}' "${MIGRATION_TMP_DIR}" \;

  echo "Moving plugins finished. The plugins will be moved back during the post-upgrade."
}

# versionXLessOrEqualThanY returns true if X is less than or equal to Y; otherwise false
function versionXLessOrEqualThanY() {
  local sourceVersion="${1}"
  local targetVersion="${2}"

  if [[ "${sourceVersion}" == "${targetVersion}" ]]; then
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
    sleep "${ERROR_SLEEP_IN_S}"
    exit 1
  fi

  if [[ ${targetVersion} =~ ${semVerRegex} ]]; then
    targetMajor=${BASH_REMATCH[1]}
    targetMinor="${BASH_REMATCH[2]}"
    targetBugfix="${BASH_REMATCH[3]}"
    targetDogu="${BASH_REMATCH[4]}"
  else
    echo "ERROR: target dogu version ${targetVersion} does not seem to be a semantic version"
    sleep "${ERROR_SLEEP_IN_S}"
    exit 1
  fi

  if [[ $((sourceMajor)) -lt $((targetMajor)) ]] ; then
    return 0;
  fi
  if [[ $((sourceMajor)) -le $((targetMajor)) && $((sourceMinor)) -lt $((targetMinor)) ]] ; then
    return 0;
  fi
  if [[ $((sourceMajor)) -le $((targetMajor)) && $((sourceMinor)) -le $((targetMinor)) && $((sourceBugfix)) -lt $((targetBugfix)) ]] ; then
    return 0;
  fi
  if [[ $((sourceMajor)) -le $((targetMajor)) && $((sourceMinor)) -le $((targetMinor)) && $((sourceBugfix)) -le $((targetBugfix)) && $((sourceDogu)) -lt $((targetDogu)) ]] ; then
    return 0;
  fi

  return 1
}

# versionXLessThanY returns true if X is less than Y; otherwise false
# This code origins from https://stackoverflow.com/a/4024263/12529534
function versionXLessThanY() {
  if [[ "${1}" == "${2}" ]]; then
    return 1
  fi

  versionXLessOrEqualThanY "${1}" "${2}"
}


# make the script only run when executed, not when sourced from bats tests
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_preupgrade "$@"
fi
