# frozen_string_literal: true

class Api::Devise::SessionsController < Devise::SessionsController
  include ActionController::MimeResponds
  include Readymade::Controller::Serialization

  respond_to :json

  def create
    super do |resource|
      return record_response(resource, view: :sign_in, jwt_token: current_token)
    end
  end

  private

  def record_params
    params.require(:user).permit!
  end

  def current_token
    request.env['warden-jwt_auth.token']
  end

  def respond_to_on_destroy
    head :no_content
  end
end
