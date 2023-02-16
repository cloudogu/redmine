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
  puts 'User saved successfully.'
rescue => error
  puts '================================================'
  puts error.message
  puts '================================================'
  puts 'User was not saved.'
end
")"

# There is no way to get an exit code on error. So we check if exception raised text appears and exit manually.
if [[ "${OUTPUT}" == *"User was not saved."* ]] || [[ "${OUTPUT}" != *"User saved successfully."* ]]; then
  echo "Could not create admin ${USERNAME} due to error: "
  echo "${OUTPUT}"
  exit 1
else
  echo "Created user ${USERNAME} successfully."
fi
