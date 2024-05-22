# frozen_string_literal: true

class Api::BaseController < ApplicationController
  include Readymade::Controller::Serialization
  include Pagy::Backend
  include ErrorHandler

  respond_to :json

  # before_action :prepare_exception_notifier # TODO: add
  prepend_before_action :authenticate_user!
  include Authorizer

  protected

  def current_token
    request.env['warden-jwt_auth.token']
  end

  private

  # def prepare_exception_notifier
  #   request.env['exception_notifier.exception_data'] = {
  #     current_user: current_user.inspect,
  #     current_organization: current_organization.inspect
  #   }
  # end

  def record_params
    params.require(record_class_key).permit!.to_h
  end

  def record_class_key
    record_class.model_name.i18n_key
  end

  def authenticate_user!
    super

    Current.user = current_user
  end
end
