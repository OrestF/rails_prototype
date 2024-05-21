# frozen_string_literal: true

require 'redis'
REDIS = Redis.new(url: RCreds.fetch(:redis, :url))
