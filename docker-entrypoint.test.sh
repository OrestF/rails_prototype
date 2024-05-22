#!/usr/bin/env bash
set -e

bundle exec rake db:prepare
bundle exec rake db:schema:load

#bundle exec rubocop -c ./.rubocop.yml || exit 1
bundle exec rspec --exclude-pattern acceptance || exit 1

# fix absolute paths in coverage.json from docker to github runner
ruby -pi.bak -e 'gsub("#{Dir.pwd}", "#{ENV[:APP_ROOT.to_s]}")' coverage/coverage.json
