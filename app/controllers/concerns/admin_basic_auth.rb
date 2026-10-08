# frozen_string_literal: true

# HTTP basic auth with the admin credentials, outside local envs.
# Credentials are read per request: `http_basic_authenticate_with` reads them when the class is loaded
# and raises ArgumentError while they are not configured (eager load in CI/production).
module AdminBasicAuth
  extend ActiveSupport::Concern

  private

  def authenticate_admin
    return if Rails.env.local?

    http_basic_authenticate_or_request_with(name: RCreds.fetch(:admin, :username), password: RCreds.fetch(:admin, :password))
  end
end
