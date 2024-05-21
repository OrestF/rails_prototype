# frozen_string_literal: true

class Api::Devise::InvitationsController < Devise::InvitationsController
  include ActionController::MimeResponds
  include Readymade::Controller::Serialization
  include Pundit::Authorization

  respond_to :json

  def update
    super do |resource|
      return record_response(resource, root: :user)
    end
  end

  private

  def update_resource_params
    params.require(:user).permit(:password, :password_confirmation, :invitation_token)
  end

  def user_not_authorized(*errors)
    render_json({ errors: errors }, :forbidden)
  end
end
