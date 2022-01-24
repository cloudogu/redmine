#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# import util functions:
# - create_secrets_yml
# - render_config_ru_template
# - render_database_yml_template
# - render_configuration_yml_template
# - exec_rake
#
# import util variables:
# - RAILS_ENV
# - REDMINE_LANG

# shellcheck disable=SC1090
# shellcheck disable=SC1091
source "${STARTUP_DIR}/util.sh"
# shellcheck disable=SC1090
# shellcheck disable=SC1091
source "${STARTUP_DIR}/pre-upgrade.sh"

function run_postupgrade() {
  FROM_VERSION="${1}"
  TO_VERSION="${2}"

  fetchDatabaseConnection

  echo "Executing Redmine post-upgrade from ${FROM_VERSION} to ${TO_VERSION}"

  if [ "${FROM_VERSION}" = "${TO_VERSION}" ]; then
    echo "FROM and TO versions are the same; Exiting..."
    exit 0
  fi

  if versionXLessOrEqualThanY "${FROM_VERSION}" "4.1.0-3"; then
    # This was added due to issue #42. There can be duplicated settings in the database. This sql statement will remove them.
    DELETE_DUPLICATE_STATEMENT="DELETE FROM settings WHERE id IN (SELECT id FROM settings WHERE NOT id IN (SELECT max(id) FROM settings GROUP BY name HAVING count(*) > 1) AND name IN (SELECT name FROM settings GROUP BY name HAVING count(name) > 1))"
    echo "post-upgrade: Deleting duplicate settings in database..."
    sql "${DELETE_DUPLICATE_STATEMENT}"
  fi

  if versionXLessOrEqualThanY "${FROM_VERSION}" "4.2.3-4" ; then
      # this migration only needs to be done if the additional plugins volume was already created
      if ! versionXLessOrEqualThanY "${FROM_VERSION}" "4.2.2-1" ; then
        migratePluginsBackToPluginsDirectory
      fi
    fi

  echo "Making sure config/secrets.yml exists..."
  create_secrets_yml

  echo "Rendering config.ru template..."
  render_config_ru_template

  echo "Rendering database.yml template..."
  render_database_yml_template

  echo "Generating configuration.yml from template..."
  render_configuration_yml_template

  install_plugins

  echo "Migrating database..."
  exec_rake db:migrate

  echo "Clearing cache..."
  exec_rake tmp:cache:clear

  echo "Set registry flag so startup script can start afterwards..."
  doguctl state "upgrade done"

  echo "Redmine post-upgrade done"
}

# moves plugins which were moved from a pre-upgrade script back to the original path
#
# Global variables:
# - MIGRATION4234_TMP_DIR - from pre-upgrade script
# - REDMINE_WORK_DIR - from pre-upgrade script
function migratePluginsBackToPluginsDirectory() {
  echo "Move plugins back to plugins directory ..."

  restorePluginsFromTmpDir "${MIGRATION4234_TMP_DIR}"

  echo "Migrating plugins finished successfully."
}

function restorePluginsFromTmpDir(){
  local source_directory="$1"

  echo "remove redmine plugin directory"
  rm -rf "${REDMINE_WORK_DIR:?}/plugins"
  echo "create new redmine plugin directory"
  mkdir "${REDMINE_WORK_DIR:?}/plugins"

  # copy plugins to plugin installation source directory
  cp -r "${source_directory:?}"/* "${PLUGIN_STORE}"
  # copy plugins back to redmine plugins directory
  cp -r "${source_directory:?}"/* "${REDMINE_WORK_DIR}/plugins/"

  rm -rf "${source_directory}"
}

# make the script only run when executed, not when sourced from bats tests)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_postupgrade "$@"
fi
