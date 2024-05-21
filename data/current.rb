# frozen_string_literal: true

class Current < ActiveSupport::CurrentAttributes
  attribute :user

  # def user=(user)
  #   super
  #   self.organization = user.organization if user.present?
  # end
end
