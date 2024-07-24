# frozen_string_literal: true

class Search::Users < BaseSearch
  ORDER_OPTIONS = order_options
  FORM_OPTIONS = {
    by_id: '*',
    by_free_text: '*',
    order_by: ORDER_OPTIONS
  }.freeze
  PERMITTED_ATTRIBUTES = FORM_OPTIONS.keys

  private

  def advanced_search_extra_params
    {
      match: :word_start
    }
  end
end
