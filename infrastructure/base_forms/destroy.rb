# frozen_string_literal: true

class BaseForms::Destroy < BaseForm
  validate :record_presence_validation
end
