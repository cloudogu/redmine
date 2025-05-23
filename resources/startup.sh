#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

echo "                                     ./////,                    "
echo "                                 ./////==//////*                "
echo "                                ////.  ___   ////.              "
echo "                         ,**,. ////  ,////A,  */// ,**,.        "
echo "                    ,/////////////*  */////*  *////////////A    "
echo "                   ////'        \VA.   '|'   .///'       '///*  "
echo "                  *///  .*///*,         |         .*//*,   ///* "
echo "                  (///  (//////)**--_./////_----*//////)   ///) "
echo "                   V///   '°°°°      (/////)      °°°°'   ////  "
echo "                    V/////(////////\. '°°°' ./////////(///(/'   "
echo "                       'V/(/////////////////////////////V'      "

SETUP_DONE_KEY="startup/setup_done"

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
#

sourceUtilExitCode=0
# shellcheck disable=SC1090
# shellcheck disable=SC1091
source "${STARTUP_DIR}"/util.sh || sourceUtilExitCode=$?
if [[ ${sourceUtilExitCode} -ne 0 ]]; then
  echo "ERROR: An error occurred while sourcing util functions."
  doguctl config "local_state" "ErrorSourceUtilFunctions"
  sleep 300
  exit 2
fi

function setDoguLogLevel() {
  echo "Mapping dogu specific log level..."
  currentLogLevel=$(doguctl config --default "WARN" "logging/root")

  case "${currentLogLevel}" in
  "ERROR")
    export REDMINE_LOGLEVEL=":error"
    ;;
  "INFO")
    export REDMINE_LOGLEVEL=":info"
    ;;
  "DEBUG")
    export REDMINE_LOGLEVEL=":debug"
    ;;
  *)
    export REDMINE_LOGLEVEL=":warn"
    ;;
  esac
  doguctl template /usr/share/webapps/redmine/config/additional_environment.rb.tpl /usr/share/webapps/redmine/config/additional_environment.rb
}

function runMain() {
  # check whether post-upgrade script is still running
  while [[ "$(doguctl config "local_state" -d "empty")" == "upgrading" ]]; do
    echo "Upgrade script is running. Waiting..."
    sleep 3
  done

  doguctl state "installing"

  echo "get variables for templates"
  FQDN=$(doguctl config --global fqdn)
  export FQDN
  DOMAIN=$(doguctl config --global domain)
  ADMIN_GROUP=$(doguctl config --global 'admin_group')
  export ADMIN_GROUP
  MAIL_ADDRESS=$(doguctl config -d "redmine@${DOMAIN}" --global mail_address)

  HOSTNAME_SETTING="${FQDN}/redmine"

  echo "render config.ru template"
  render_config_ru_template

  echo "render database.yml template"
  render_database_yml_template

  setDoguLogLevel

  # Make sure secrets.yml exists
  create_secrets_yml

  # wait until postgresql passes all health checks
  echo "wait until postgresql passes all health checks"
  if ! doguctl healthy --wait --timeout 120 postgresql; then
    echo "timeout reached by waiting of postgresql to get healthy"
    exit 1
  fi

  # wait some more time for PostgreSQL so the next check wont fail
  # TODO: check why the if statement below sometimes fails if there is no sleep
  sleep 10

  SETUP_DONE=$(doguctl config "${SETUP_DONE_KEY}" --default "false")
  # Check if Redmine has been installed already
  if [[ "${SETUP_DONE}" == "true" ]]; then
    echo "Redmine (database) has been installed already."
    # update FQDN in settings
    # we need to update the fqdn on every start, because of possible changes
    sql "UPDATE settings SET value='${HOSTNAME_SETTING}' WHERE name='host_name';"
  else

    # Create the database structure
    echo "Creating database structure..."
    exec_rake db:migrate

    # insert default configuration data into database
    echo "Inserting default configuration data into database..."
    exec_rake redmine:load_default_data

    echo "Writing authentication settings to database..."
    sql "INSERT INTO settings (name, value, updated_on) VALUES ('login_required', 1, now());"

    # Enabling REST API
    sql "INSERT INTO settings (name, value, updated_on) VALUES ('rest_api_enabled', 1, now());"

    # write url settings to database
    sql "INSERT INTO settings (name, value, updated_on) VALUES ('host_name','${HOSTNAME_SETTING}', now());"
    sql "INSERT INTO settings (name, value, updated_on) VALUES ('protocol','https', now());"
    sql "INSERT INTO settings (name, value, updated_on) VALUES ('emails_footer', E'You have received this notification because you have either subscribed to it, or are involved in it.\\r\\nTo change your notification preferences, please click here: https://${FQDN}/redmine/my/account', now());"

    # set default email address
    sql "INSERT INTO settings (name, value, updated_on) VALUES ('mail_from','${MAIL_ADDRESS}', now());"

    # set theme to cloudogu, do this only on installation not on a upgrade
    # because the user should be able to change the theme
    sql "INSERT INTO settings (name, value, updated_on) VALUES ('ui_theme','Cloudogu', now());"

    # we use markdown as default format, however it can be changed
    sql "INSERT INTO settings (name, value, updated_on) VALUES ('text_formatting', 'common_mark', now());"

    # Remove default admin account
    sql "DELETE FROM users WHERE login='admin';"

    doguctl config "${SETUP_DONE_KEY}" "true"
  fi

  # install manual installed plugins
  install_plugins

  # make sure temp, file and log folders are writable
  mkdir -p tmp tmp/pdf public/plugin_assets
  chown -R "${USER}":"${USER}" files log tmp public/plugin_assets
  chmod -R 755 files log tmp public/plugin_assets

  # tasks that require usage of a temporary admin and redmine daemon
  background_configuration_tasks

  # Create links
  if [ ! -e "${WORKDIR}"/public/redmine ]; then
    ln -s "${WORKDIR}" "${WORKDIR}"/public/
  fi
  if [ ! -e "${WORKDIR}"/stylesheets ]; then
    ln -s "${WORKDIR}"/public/* "${WORKDIR}"
  fi

  echo "Generate configuration.yml from template"
  render_configuration_yml_template

  # remove old pid
  RPID="${WORKDIR}/tmp/pids/server.pid"
  if [ -f "${RPID}" ]; then
    rm -f "${RPID}"
  fi

  echo "Clearing sessions..."
  exec_rake db:sessions:clear

  doguctl state "ready"
  doguctl config --rm "local_state"

  # Start redmine
  echo "Starting redmine..."
  exec su - redmine -c "AUTO_MANAGED=true RAILS_RELATIVE_URL_ROOT=${RAILS_RELATIVE_URL_ROOT} puma -e ${RAILS_ENV} -p 3000"
}

# make the script only run when executed, not when sourced from bats tests)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  fetchDatabaseConnection
  runMain
fi
