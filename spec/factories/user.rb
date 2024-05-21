# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { 'password' }

    trait :with_accepted_invitation do
      invitation_accepted_at { Time.current }
    end

    trait :locked do
      locked_at { Time.current }
    end
  end
end
