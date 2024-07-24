# frozen_string_literal: true

module Users::Searchable
  extend ActiveSupport::Concern

  included do
    extend Searchable.new(search_params: { word_start: %i[id email] })

    def search_fields
      {
        id: id,
        email: email
      }
    end
  end
end
