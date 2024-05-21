# frozen_string_literal: true

class Users::Forms::SendPasswordRestoreEmail < BaseForm
  PERMITTED_ATTRIBUTES = %i[email accept_password_url].freeze
  REQUIRED_ATTRIBUTES = PERMITTED_ATTRIBUTES.freeze

  attr_accessor(*PERMITTED_ATTRIBUTES, :record)

  validate :record_presence_validation
end
