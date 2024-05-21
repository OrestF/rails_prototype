# frozen_string_literal: true

class Users::Operations::SendPasswordRestoreEmail < BaseOperation
  def call
    return validation_fail unless form_valid?

    set_accept_password_url
    send_reset_password_instructions

    success(record: record)
  end

  private

  def form_class
    Users::Forms::SendPasswordRestoreEmail
  end

  def set_accept_password_url
    record.accept_password_url = record_params[:accept_password_url]
  end

  def send_reset_password_instructions
    record.send_reset_password_instructions
  end
end
