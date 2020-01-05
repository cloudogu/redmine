#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

FROM_VERSION="${1}"
TO_VERSION="${2}"

echo "Executing Redmine pre-upgrade from ${FROM_VERSION} to ${TO_VERSION}"

if [ "${FROM_VERSION}" = "${TO_VERSION}" ]; then
  echo "FROM and TO versions are the same; Exiting..."
  exit 0
fi

echo "Set registry flag so startup script waits for post-upgrade to finish..."
doguctl state "upgrading"

echo "Redmine pre-upgrade done"

echo "Please be aware that after any upgrade of redmine existing session cookies"
echo "will most likely stop working. If a user tries to access redmine with a"
echo "pre-upgrade session cookie it will result in an error."
