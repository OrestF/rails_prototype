#!/usr/bin/env bash
set -e

# Production skips the development and test gems (Bundler 4 removed `bundle install --without`)
if [[ "$RAILS_ENV" == "production" ]]; then
  export BUNDLE_WITHOUT=development:test
fi
bundle install --jobs 20 --retry 5

# Background jobs run on Solid Queue. A project that moves to Sidekiq replaces the command below and keeps this
# file: Compose, CI and deploys run it by name.
#   bundle exec sidekiq -C config/sidekiq.yml
bundle exec bin/jobs
