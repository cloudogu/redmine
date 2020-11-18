#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# shellcheck disable=SC1091
source /util.sh

FROM_VERSION="${1}"
TO_VERSION="${2}"

echo "Executing Redmine pre-upgrade from ${FROM_VERSION} to ${TO_VERSION}"

if [ "${FROM_VERSION}" = "${TO_VERSION}" ]; then
  echo "FROM and TO versions are the same; Exiting..."
  exit 0
fi

doguctl state "upgrading"

if [[ "${FROM_VERSION}" =~ ^v3.*$ || "${FROM_VERSION}" =~ ^[v]*4.((0.5-1)|(1.0-[123]))$ ]]; then
  DELETE_DUPLICATE_STATEMENT="DELETE FROM settings WHERE id IN (SELECT id FROM settings WHERE NOT id IN (SELECT max(id) FROM settings GROUP BY name HAVING count(*) > 1) AND name IN (SELECT name FROM settings GROUP BY name HAVING count(name) > 1))"
  echo "Pre-upgrade: Deleting duplicate settings in database..."
  sql "${DELETE_DUPLICATE_STATEMENT}"
fi

echo "Set registry flag so startup script waits for post-upgrade to finish..."
echo "Redmine pre-upgrade done"
