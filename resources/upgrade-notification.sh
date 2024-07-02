#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# shellcheck disable=SC1090
# shellcheck disable=SC1091
source "${STARTUP_DIR}/util.sh"

FROM_VERSION="${1}"
RED='\033[0;31m'
COLOR_OFF='\033[0m'

echo "Please be aware that after any upgrade of redmine existing session cookies"
echo "will most likely stop working. If a user tries to access redmine with a"
echo "pre-upgrade session cookie it may result in an error."

if versionXLessOrEqualThanY "${FROM_VERSION}" "5.1.3-1" ; then
    printf "%s ~~~~ WARNING ~~~~\n\n" "${RED}"
    printf "%s Starting with Redmine 5.1.3-1, the previous formatter 'Markdown' is deprecated in favor of the formatter 'CommonMark Markdown (github-flavoured)' which no longer supports underlining (but adds lots of new features). Underlined text will be rendered differently. The deprecated markdown formatter may be removed in future versions.\n\n" "${COLOR_OFF}"
    printf "For more information please see the changelog or release notes.\n\n"
fi

