# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      case user.role
      when 'admin'
        scope
      else
        User.none
      end
    end
  end

  def profile?
    user.can?(:user, :read) { my_profile? }
  end

  def update_profile?
    user.can?(:user, :update) { my_profile? }
  end

  private

  def my_profile?
    return false if user.nil?

    user == record
  end

  def own_org?
    record&.organization == organization
  end
end
