#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

echo "Please be aware that after any upgrade of redmine existing session cookies"
echo "will most likely stop working. If a user tries to access redmine with a"
echo "pre-upgrade session cookie it may result in an error."
