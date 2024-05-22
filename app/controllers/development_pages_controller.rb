# frozen_string_literal: true

class DevelopmentPagesController < ActionController::Base
  http_basic_authenticate_with name: RCreds.fetch(:admin, :username), password: RCreds.fetch(:admin, :password), if: :auth_env?

  layout 'development_pages'

  def home
  end

  private

  def auth_env?
    !Rails.env.local?
  end
end
