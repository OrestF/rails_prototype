#!/usr/bin/env bash
rm -f tmp/pids/server.pid

bundle exec rake db:migrate 2>/dev/null || bundle exec rake db:setup

if [[ "$RAILS_ENV" == "production" ]]; then\
  bundle install --jobs 20 --retry 5 --without development test;\
  else bundle install --jobs 20 --retry 5; fi

yarn install

bundle exec puma -C "config/puma.rb"
