#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

USERNAME="${1}"
PASSWORD="${2}"

OUTPUT="$(RAILS_ENV=production bundle exec rails console <<< "
begin
  user = User.new(:language => Setting.default_language, :mail_notification => Setting.default_notification_option, :admin => true)
  user.login = '${USERNAME}'
  user.password = '${PASSWORD}'
  user.password_confirmation = '${PASSWORD}'
  user.lastname = '${USERNAME}'
  user.firstname = '${USERNAME}'
  user.mail = '${USERNAME}@${USERNAME}.de'
  user.save!
rescue => error
  puts error.message
  raise 'User was not saved'
end
")"


# There is no way to get an exit code on error. So we check if exception raised text appears and exit manually.
if [[ "${OUTPUT}" == *"RuntimeError (User was not saved)"* ]]; then
  echo "Could not create temporary admin user due to error: "
  printf '%s\n' "${OUTPUT#*end}"
  exit 1
fi
