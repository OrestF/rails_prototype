#!/usr/bin/env bash
set -e

rm -f tmp/pids/server.pid

bundle install --jobs 20 --retry 5

bundle exec rake db:prepare
#bundle exec rake db:setup

# Precompile assets outside development: in development the app dir is bind-mounted, and precompiled
# public/assets would make the server ignore asset changes (on the host too)
if [ "$RAILS_ENV" != "development" ]; then
  bundle exec rails assets:precompile
fi

bundle exec puma -C "config/puma.rb"
