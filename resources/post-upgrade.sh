#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

FROM_VERSION="${1}"
TO_VERSION="${2}"

function exec_rake() {
  RAILS_ENV="production" REDMINE_LANG="en" rake --trace -f ${WORKDIR}/Rakefile $*
}

echo "executing update ${FROM_VERSION} to ${TO_VERSION}"

exec_rake db:migrate
exec_rake redmine:plugins:migrate
