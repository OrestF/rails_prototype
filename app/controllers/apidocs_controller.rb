# frozen_string_literal: true

class ApidocsController < Apitome::DocsController
  http_basic_authenticate_with name: RCreds.fetch(:admin, :username), password: RCreds.fetch(:admin, :password), if: :auth_env?

  private

  def auth_env?
    !Rails.env.local?
  end
end
