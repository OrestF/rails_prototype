# frozen_string_literal: true

class Api::V1::UsersController < Api::V1::BaseController
  skip_before_action :verify_record, :verify_class, only: %i[profile update_profile]

  def profile
    authorize current_user

    record_response(current_user, root: :user, view: :full)
  end

  def update_profile
    authorize current_user

    operation_response(
      Users::Operations::Update.call(
        record: current_user,
        record_params: record_params
      ),
      root: :user,
      view: :full
    )
  end
end
