#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# WORKDIR is a Dockerfile global variable
REDMINE_WORK_DIR="${WORKDIR}"
MIGRATION_TMP_DIR="/var/tmp/redmine/plugins/migration4.4.2.1"

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
# This code origins from https://stackoverflow.com/a/4024263/12529534
function versionXLessOrEqualThanY() {
  [[ "${1}" == "$(echo -e "${1}\n${2}" | sort -V | head -n1)" ]]
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
