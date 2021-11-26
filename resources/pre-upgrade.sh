#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

FROM_VERSION=
TO_VERSION=

function run_preupgrade() {
  FROM_VERSION="${1}"
  TO_VERSION="${2}"

  setSemanticVersionVars "${FROM_VERSION}" "${TO_VERSION}"

# dump database if TO_MAJOR_VERSION is equal or higher than 12 and FROM_MAJOR_VERSION is lower than 12
if [[ "${TO_MAJOR_VERSION}" -ge 12 ]] && [[ "${FROM_MAJOR_VERSION}" -lt 12 ]]; then
    echo "Dumping database to ${PGDATA}/postgresqlFullBackup.dump..."
    pg_dumpall -U postgres -f "${PGDATA}"/postgresqlFullBackup.dump
    echo "Finished dumping database"
fi
  echo "Executing Redmine pre-upgrade from ${FROM_VERSION} to ${TO_VERSION}"

  if [ "${FROM_VERSION}" = "${TO_VERSION}" ]; then
    echo "FROM and TO versions are the same; Exiting..."
    exit 0
  fi

  

  echo "Set registry flag so startup script waits for post-upgrade to finish..."
  doguctl state "upgrading"

  doguctl config "startup/setup_done" "true"

  echo "Redmine pre-upgrade done"
}

function setSemanticVersionVars() {
  FROM_MAJOR_VERSION=$(echo "${FROM_VERSION}" | cut -d '.' -f1)
  TO_MAJOR_VERSION=$(echo "${TO_VERSION}" | cut -d '.' -f1)
  FR
}

# versionXLessOrEqualThanY returns true if X is less than or equal to Y; otherwise false
# This code origins from https://stackoverflow.com/a/4024263/12529534
function versionXLessOrEqualThanY() {
    [  "${1}" = "`echo -e "${1}\n${2}" | sort -V | head -n1`" ]
}

# versionXLessOrEqualThanY returns true if X is less than Y; otherwise false
# This code origins from https://stackoverflow.com/a/4024263/12529534
function versionXLessThanY() {
    [ "${1}" = "${2}" ] && return 1 || versionXLessOrEqualThanY "${1}" "${2}"
}


# make the script only run when executed, not when sourced from bats tests)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_preupgrade "$@"
fi
