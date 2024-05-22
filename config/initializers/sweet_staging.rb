# frozen_string_literal: true

if defined?(SweetStaging)
  SweetStaging.setup do |config|
    config.enabled = !Rails.env.production?
    config.fetch_timeout = 1000
    config.console = true
    config.logs = [
      {
        name: "xlog_#{Rails.env}.log",
        path: "log/xlog_#{Rails.env}.log"
      },
      {
        name: "#{Rails.env}.log",
        path: "log/#{Rails.env}.log"
      },
      {
        name: "sidekiq.log",
        path: 'log/sidekiq.log'
      }
    ]
    config.commands = []

    # protect your Performance Dashboard with HTTP BASIC password
    config.http_basic_authentication_enabled   = true
    config.http_basic_authentication_user_name = RCreds.fetch(:admin, :username)
    config.http_basic_authentication_password  = RCreds.fetch(:admin, :password)

    # if you need an additional rules to check user permissions
    # config.verify_access_proc = proc { |controller| true }
    # for example when you have `current_user`
    # config.verify_access_proc = proc { |controller| controller.current_user && controller.current_user.admin? }
  end
end
