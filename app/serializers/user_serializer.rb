# frozen_string_literal: true

class UserSerializer < ApplicationSerializer
  DEFAULT_FIELDS = %i[
    email
    created_at
    invitation_sent_at
    invitation_accepted_at
  ].freeze

  fields(*DEFAULT_FIELDS)

  view :sign_in do
    field :jwt_token do |_, options|
      options[:jwt_token]
    end
  end

  view :full do
    # add views here
  end
end
