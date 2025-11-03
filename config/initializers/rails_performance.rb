# frozen_string_literal: true

if defined?(RailsPerformance)
  def local_env?
    Rails.env.development? || Rails.env.test?
  end

  RailsPerformance.setup do |config|
    config.redis    = Redis.new(url: RCreds.fetch(:redis, :url, default: 'redis://localhost:6379/0'))
    config.duration = 4.hours

    config.debug    = false # currently not used>
    config.enabled  = true

    # default path where to mount gem,
    # alternatively you can mount the RailsPerformance::Engine in your routes.rb
    config.mount_at = '/apm'

    # protect your Performance Dashboard with HTTP BASIC password
    config.http_basic_authentication_enabled = !local_env?
    config.http_basic_authentication_user_name = RCreds.fetch(:admin, :username)
    config.http_basic_authentication_password  = RCreds.fetch(:admin, :password)

    # if you need an additional rules to check user permissions
    config.verify_access_proc = proc { |_controller| true }
    # for example when you have `current_user`
    # config.verify_access_proc = proc { |controller| controller.current_user && controller.current_user.admin? }

    # config home button link
    config.home_link = '/'
  end
end
