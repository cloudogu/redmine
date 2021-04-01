#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

USERNAME="${1}"
PASSWORD="${2}"

bundle exec rails console production <<< "
user = User.new(:language => Setting.default_language, :mail_notification => Setting.default_notification_option, :admin => true)
user.login = '${USERNAME}'
user.password = '${PASSWORD}'
user.password_confirmation = '${PASSWORD}'
user.lastname = '${USERNAME}'
user.firstname = '${USERNAME}'
user.mail = '${USERNAME}@${USERNAME}.de'
user.save!
"
