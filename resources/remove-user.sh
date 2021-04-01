#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

USERNAME="${1}"

RAILS_ENV=production bundle exec rails console <<< "
user = User.where(login: '${USERNAME}').first
unless user.nil?
  user.destroy
end
" >> /dev/null
