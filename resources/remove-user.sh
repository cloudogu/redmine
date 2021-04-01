#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

USERNAME="${1}"

OUTPUT="$(RAILS_ENV=production bundle exec rails console <<< "
user = User.where(login: '${USERNAME}').first
begin
  user.destroy unless user.nil?
rescue => error
  puts error.message
  raise 'User was not saved'
end
")"

# There is no way to get an exit code on error. So we check if exception raised text appears and exit manually.
if [[ "${OUTPUT}" == *"RuntimeError (User was not saved)"* ]]; then
  echo "Could not remove user ${USERNAME} due to error: "
  printf '%s\n' "${OUTPUT#*end}"
  exit 1
else
  echo "Removed user ${USERNAME} successfully."
fi
