#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# WORKDIR is a Dockerfile global variable
REDMINE_WORK_DIR="${WORKDIR}"
DEFAULT_PLUGIN_DIRECTORY="${WORKDIR}/defaultPlugins"
MIGRATION_VERSION_4234_TMP_DIR="/var/tmp/redmine/plugins/migration4.2.3.4"

function run_preupgrade() {
  FROM_VERSION="${1}"
  TO_VERSION="${2}"

  echo "Executing Redmine pre-upgrade from ${FROM_VERSION} to ${TO_VERSION}"

  if [ "${FROM_VERSION}" = "${TO_VERSION}" ]; then
    echo "FROM and TO versions are the same; Exiting..."
    exit 0
  fi

  echo "Set registry flag so startup script waits for post-upgrade to finish..."
  doguctl config "local_state" "upgrading"

  if versionXLessOrEqualThanY "${FROM_VERSION}" "4.2.3-4" ; then
    # this migration only needs to be done if the additional plugins volume was already created
    if ! versionXLessOrEqualThanY "${FROM_VERSION}" "4.2.2-1" ; then
      movePluginsToTempDirM4234
    fi
  fi

  doguctl config "startup/setup_done" "true"

  echo "Redmine pre-upgrade done"
}

function movePluginsToTempDirM4234() {
  echo "Move plugins to temporary directory..."

  movePluginsToTmpDir "${MIGRATION_VERSION_4234_TMP_DIR}"

  echo "Moving plugins finished. The plugins will be moved back during the post-upgrade."
}

function movePluginsToTmpDir(){
  local target_directory="$1"

  mkdir -p "${target_directory}"
  find "${REDMINE_WORK_DIR}"/plugins/* -maxdepth 0 -type d -exec mv '{}' "${target_directory}" \;

  PLUGINS=$(ls "${DEFAULT_PLUGIN_DIRECTORY}")
  for PLUGIN_PACKAGE in ${PLUGINS}; do
    if [[ -d "${target_directory}/${PLUGIN_PACKAGE}" ]]; then
      rm -rf "${target_directory:?}/${PLUGIN_PACKAGE}"
    fi
  done
}

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
