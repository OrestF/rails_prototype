# frozen_string_literal: true

module Users
  module TemporaryData
    extend ActiveSupport::Concern

    def accept_invitation_url
      REDIS.get("users/#{email}/accept_invitation_url")
    end

    def accept_invitation_url=(value)
      REDIS.set("users/#{email}/accept_invitation_url", value, ex: default_ex)
    end

    def accept_password_url
      REDIS.get("users/#{email}/accept_password_url")
    end

    def accept_password_url=(value)
      REDIS.set("users/#{email}/accept_password_url", value, ex: default_ex)
    end

    def accept_confirm_url
      REDIS.get("users/#{email}/accept_confirm_url")
    end

    def accept_confirm_url=(value)
      REDIS.set("users/#{email}/accept_confirm_url", value, ex: default_ex)
    end

    private

    def default_ex
      24.hours.from_now.to_i
    end
  end
end
