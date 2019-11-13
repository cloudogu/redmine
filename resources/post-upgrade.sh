#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

FROM_VERSION="${1}"
TO_VERSION="${2}"

if [ "${FROM_VERSION}" = "${TO_VERSION}" ]; then
  exit 0
fi

function exec_rake() {
  RAILS_ENV="production" REDMINE_LANG="en" rake --trace -f "${WORKDIR}"/Rakefile "$*"
}

echo "Executing Redmine upgrade from ${FROM_VERSION} to ${TO_VERSION}"

echo "Migrating database..."
exec_rake db:migrate

echo "Migrating plugins..."
exec_rake redmine:plugins:migrate

echo "Clearing cache..."
exec_rake tmp:cache:clear
