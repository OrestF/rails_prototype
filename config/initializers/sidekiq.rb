# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq/web'
require 'sidekiq/cron/web'

if Rails.env.production? || Rails.env.staging? || Rails.env.preprod?

  Sidekiq::Web.use(Rack::Auth::Basic) do |username, password|
    Rack::Utils.secure_compare(Digest::SHA256.hexdigest(username),
                               Digest::SHA256.hexdigest(RCreds.fetch(:admin, :username))) &
      Rack::Utils.secure_compare(Digest::SHA256.hexdigest(password),
                                 Digest::SHA256.hexdigest(RCreds.fetch(:admin, :password)))
  end
end

url = RCreds.fetch(:redis, :url, default: 'redis://localhost:6379/0')
redis_params = { url: url, size: 12, network_timeout: 5 }

Sidekiq.configure_server { |config| config.redis = redis_params }
Sidekiq.configure_client { |config| config.redis = redis_params }

Sidekiq::Cron::Job.load_from_hash(YAML.load_file('config/sidekiq_schedule.yml') || {}) unless Rails.env.test?
