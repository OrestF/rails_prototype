# frozen_string_literal: true

class Api::Devise::PasswordsController < Devise::PasswordsController
  include Readymade::Controller::Serialization

  respond_to :json

  def create
    record_response(
      Users::Operations::SendPasswordRestoreEmail.call(record: record, record_params: resource_params.permit!).data[:record],
      root: resource_name
    )
  end

  def update
    super do |resource|
      return record_response(resource, root: resource_name)
    end
  end

  private

  def record
    @record ||= User.find_by(email: resource_params[:email])
  end
end
