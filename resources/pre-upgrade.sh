#!/bin/bash

# older installation of redmine exposed the core plugins to the
# plugin volume, these exposed plugin could be old and must be
# removed.

set -o errexit
set -o nounset
set -o pipefail

PLUGIN_DIRECTORY="${WORKDIR}/plugins"
CORE_PLUGINS="redmine_activerecord_session_store redmine_cas"

for CP in ${CORE_PLUGINS}; do
  CP_DIR="${PLUGIN_DIRECTORY}/${CP}"
  if [ -d "${CP_DIR}" ]; then
    echo "removing old installation of ${CP}..."
    rm -rf "${CP_DIR}"
  fi
done