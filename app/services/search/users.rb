# frozen_string_literal: true

class Search::Users < BaseSearch
  FORM_OPTIONS = User.options_for_search
  PERMITTED_ATTRIBUTES = FORM_OPTIONS.keys

  private

  def advanced_search_extra_params
    {
      match: :word_start
    }
  end
end
