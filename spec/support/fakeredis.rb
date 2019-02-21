# frozen_string_literal: true

require 'fakeredis'
require 'sidekiq'

redis_opts = {}
redis_opts[:driver] = Redis::Connection::Memory if defined?(Redis::Connection::Memory)

Sidekiq.configure_client do |config|
  config.redis = redis_opts
end

Sidekiq.configure_server do |config|
  config.redis = redis_opts
end
