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
#
# shellcheck disable=SC1091
source /util.sh

# check whether post-upgrade script is still running
while [[ "$(doguctl state)" == "upgrading" ]]; do
  echo "Upgrade script is running. Waiting..."
  sleep 3
done

doguctl state "installing"

echo "get variables for templates"
FQDN=$(doguctl config --global fqdn)
DOMAIN=$(doguctl config --global domain)
ADMIN_GROUP=$(doguctl config --global 'admin_group')
MAIL_ADDRESS=$(doguctl config -d "redmine@${DOMAIN}" --global mail_address)

echo "get data for database connection"
DATABASE_USER=$(doguctl config -e sa-postgresql/username)
DATABASE_USER_PASSWORD=$(doguctl config -e sa-postgresql/password)
DATABASE_DB=$(doguctl config -e sa-postgresql/database)

echo "get plugin locations"
PLUGIN_STORE="/var/tmp/redmine/plugins"
PLUGIN_DIRECTORY="${WORKDIR}/plugins"

HOSTNAME_SETTING="${FQDN}/redmine"

function sql(){
  PGPASSWORD="${DATABASE_USER_PASSWORD}" psql --host "postgresql" --username "${DATABASE_USER}" --dbname "${DATABASE_DB}" -1 -c "${1}"
}

function install_plugins(){
  echo "installing plugins"

  PLUGINS=$(ls "${PLUGIN_STORE}")
  for PLUGIN_PACKAGE in ${PLUGINS}; do
    install_plugin "${PLUGIN_PACKAGE}"
  done

  # install missing gems only if external plugins are going to install
  if [ "x${PLUGINS}" != "x" ]; then
    echo "install missing gems ..."
    RAILS_ENV="${RAILS_ENV}" REDMINE_LANG="${REDMINE_LANG}" bundle install
    echo "missing gems ... installed"
  fi

  # run migrations always, because core plugins need also a db migration
  echo "running plugin migrations..."
  exec_rake redmine:plugins:migrate
  echo "plugin migrations... done"
}

# installs or upgrades the given plugin
function install_plugin(){
  NAME="${1}"
  SOURCE="${PLUGIN_STORE}/${NAME}"
  TARGET="${PLUGIN_DIRECTORY}/${NAME}"

  if [ ! -d "${SOURCE}" ]; then
    exit 1
  fi

  echo "install plugin ${NAME}"
  if [ -d "${TARGET}" ]; then
    rm -rf "${TARGET}"
  fi

  cp -rf "${SOURCE}" "${TARGET}"
}

echo "render config.ru template"
render_config_ru_template

echo "render database.yml template"
render_database_yml_template

# Make sure secrets.yml exists
create_secrets_yml

# export variables for auth_source_cas.rb
export FQDN
export ADMIN_GROUP

# wait until postgresql passes all health checks
echo "wait until postgresql passes all health checks"
if ! doguctl healthy --wait --timeout 120 postgresql; then
  echo "timeout reached by waiting of postgresql to get healthy"
  exit 1
fi

# wait some more time for PostgreSQL so the next check wont fail
# TODO: check why the if statement below sometimes fails if there is no sleep
sleep 10

# Check if Redmine has been installed already
if 2>/dev/null 1>&2 sql "select count(*) from settings;"; then
  echo "Redmine (database) has been installed already."
  # update FQDN in settings
  # we need to update the fqdn on every start, because of possible changes
  sql "UPDATE settings SET value='${HOSTNAME_SETTING}' WHERE name='host_name';"
  sql "UPDATE settings SET value=E'--- !ruby/hash:ActionController::Parameters \\nenabled: 1 \\ncas_url: https://${FQDN}/cas \\nattributes_mapping: firstname=givenName&lastname=surname&mail=mail \\nautocreate_users: 1' WHERE name='plugin_redmine_cas';" > /dev/null 2>&1
else

  # Create the database structure
  echo "Creating database structure..."
  exec_rake db:migrate

  # Session migration
  echo "Generating session migration..."
  rails generate active_record:session_migration
  echo "Executing session migration..."
  exec_rake db:migrate

  # Set session store
  echo "Writing session_store.rb..."
  echo 'Rails.application.config.session_store :active_record_store, :key => '\''_sessions'\'' ' > "${WORKDIR}"/config/initializers/session_store.rb

  # insert default configuration data into database
  echo "Inserting default configuration data into database..."
  exec_rake redmine:load_default_data

  echo "Writing cas plugin settings to database..."
  sql "INSERT INTO settings (name, value, updated_on) VALUES ('plugin_redmine_cas', E'--- !ruby/hash:ActionController::Parameters \\nenabled: 1 \\ncas_url: https://${FQDN}/cas \\nattributes_mapping: firstname=givenName&lastname=surname&mail=mail \\nautocreate_users: 1', now());"
  sql "INSERT INTO settings (name, value, updated_on) VALUES ('login_required', 1, now());"

  # Enabling REST API
  sql "INSERT INTO settings (name, value, updated_on) VALUES ('rest_api_enabled', 1, now());"

  # Insert auth_sources record for AuthSourceCas authentication source
  sql "INSERT INTO auth_sources VALUES (DEFAULT, 'AuthSourceCas', 'Cas', 'cas.example.com', 1234, 'myDbUser', 'myDbPass', 'dbAdapter:dbName', 'name', 'firstName', 'lastName', 'email', true, false, null, null);"

  # write url settings to database
  sql "INSERT INTO settings (name, value, updated_on) VALUES ('host_name','${HOSTNAME_SETTING}', now());"
  sql "INSERT INTO settings (name, value, updated_on) VALUES ('protocol','https', now());"
  sql "INSERT INTO settings (name, value, updated_on) VALUES ('emails_footer', E'You have received this notification because you have either subscribed to it, or are involved in it.\\r\\nTo change your notification preferences, please click here: https://${FQDN}/redmine/my/account', now());"

  # set default email address
  sql "INSERT INTO settings (name, value, updated_on) VALUES ('mail_from','${MAIL_ADDRESS}', now());"

  # set theme to cloudogu, do this only on installation not on a upgrade
  # because the user should be able to change the theme
  sql "INSERT INTO settings (name, value, updated_on) VALUES ('ui_theme','Cloudogu', now());"

  # enable gravatar
  sql "INSERT INTO settings (name, value, updated_on) VALUES ('gravatar_enabled', 1, now());"
  sql "INSERT INTO settings (name, value, updated_on) VALUES ('gravatar_default', 'identicon', now());"

  # we use markdown as default format, however it can be changed
  sql "INSERT INTO settings (name, value, updated_on) VALUES ('text_formatting', 'markdown', now());"

  # Remove default admin account
  sql "DELETE FROM users WHERE login='admin';"
fi

# install manual installed plugins
install_plugins

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

# make sure temp, file and log folders are writable
# TODO should tmp be a volume, because of performance?
mkdir -p tmp tmp/pdf public/plugin_assets
chown -R "${USER}":"${USER}" files log tmp public/plugin_assets
chmod -R 755 files log tmp public/plugin_assets

doguctl state "ready"

# Start redmine
echo "Starting redmine..."
exec su - redmine -c "FQDN=${FQDN} ADMIN_GROUP=${ADMIN_GROUP} puma -e ${RAILS_ENV} -p 3000"
