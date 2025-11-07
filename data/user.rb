# frozen_string_literal: true

class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  include Passpartu
  include Users::TemporaryData
  # include Users::Searchable # DEPRECATED

  # Include default devise modules. Others available are:
  # :confirmable, :trackable and :omniauthable
  devise :database_authenticatable, :jwt_authenticatable, :invitable, :lockable, :registerable,
         :recoverable, :validatable, :timeoutable, jwt_revocation_strategy: self,
         lock_strategy: :none, unlock_strategy: :none

  def role
    'admin'
  end
end
