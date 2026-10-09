# frozen_string_literal: true

module Users
  module TemporaryData
    extend ActiveSupport::Concern

    EXPIRES_IN = 24.hours

    def accept_invitation_url
      Rails.cache.read(temporary_data_key(:accept_invitation_url))
    end

    def accept_invitation_url=(value)
      write_temporary_data(:accept_invitation_url, value)
    end

    def accept_password_url
      Rails.cache.read(temporary_data_key(:accept_password_url))
    end

    def accept_password_url=(value)
      write_temporary_data(:accept_password_url, value)
    end

    def accept_confirm_url
      Rails.cache.read(temporary_data_key(:accept_confirm_url))
    end

    def accept_confirm_url=(value)
      write_temporary_data(:accept_confirm_url, value)
    end

    private

    def temporary_data_key(name)
      "users/#{email}/#{name}"
    end

    def write_temporary_data(name, value)
      Rails.cache.write(temporary_data_key(name), value, expires_in: EXPIRES_IN)
    end
  end
end
