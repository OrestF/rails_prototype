#!/usr/bin/env bash
set -e

if [[ "$RAILS_ENV" == "production" ]]; then\
  bundle install --jobs 20 --retry 5 --without development test;\
  else bundle install --jobs 20 --retry 5; fi

bundle exec sidekiq -C config/sidekiq.yml
