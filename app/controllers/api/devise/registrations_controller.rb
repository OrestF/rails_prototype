# frozen_string_literal: true

class Api::Devise::RegistrationsController < Devise::RegistrationsController
  include Readymade::Controller::Serialization

  respond_to :json

  def create
    super do |resource|
      return record_response(resource, root: resource_name)
    end
  end

  # def update
  #   super
  # end

  private

  def record_params
    params.require(:user).permit!
  end
end
