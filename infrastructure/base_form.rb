# frozen_string_literal: true

class BaseForm < Readymade::Form
  def record_presence_validation
    errors.add(:record, 'cannot be blank') if record.blank?
  end
end
