#!/usr/bin/env bash
set -e

rm -f tmp/pids/server.pid

bundle install --jobs 20 --retry 5

bundle exec rake db:prepare
#bundle exec rake db:setup

# Precompile assets
rails assets:precompile

bundle exec puma -C "config/puma.rb"
