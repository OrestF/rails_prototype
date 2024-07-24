# frozen_string_literal: true

class BaseSearch < BaseAction
  attr_reader :scope, :filter_params

  def self.order_options
    name.split('::')[-1].classify.safe_constantize.new.search_data.keys.each_with_object({}) do |field_name, hash|
      hash[field_name] = %i[asc desc]
    end
  end

  def call
    reindex_if_needed
    return scope if permitted_filter_params.blank?

    search_results
  end

  private

  def reindex_if_needed
    return unless advanced?

    scope.klass.reindex_if_needed(scope.klass.all)
  end

  def permitted_filter_params
    return {} if filter_params.blank?

    filter_attributes = filter_params.is_a?(ActionController::Parameters) ? filter_params.permit!.to_h : filter_params
    filter_attributes.slice(*permitted_attributes)
  end

  def search_results
    return scope.filter_collection(permitted_filter_params.except(:order_by)).order(permitted_filter_params[:order_by]) unless advanced?

    advanced_search
  end

  def advanced?
    Searchkick.models.include?(scope.klass)
  end

  def advanced_query_param
    @advanced_query_param ||= filter_params.delete(:by_free_text) || '*'
  end

  # rubocop:disable Metrics/AbcSize
  def advanced_search
    advanced_search_response_ids = scope.klass.search(
      advanced_query_param,
      misspellings: false,
      scope_results: ->(r) { r.search_import.filter_collection(permitted_filter_params.except(:order_by)) },
      order: permitted_order_params,
      **advanced_search_extra_params
    ).pluck(scope.klass.primary_key.to_sym)

    scope.where(scope.klass.primary_key.to_sym => advanced_search_response_ids)
         .in_order_of(scope.klass.primary_key.to_sym, advanced_search_response_ids)
  end
  # rubocop:enable Metrics/AbcSize

  def advanced_search_extra_params
    {}
  end

  def permitted_order_params
    return {} if permitted_filter_params[:order_by].blank?

    permitted_filter_params[:order_by].slice(*self.class::ORDER_OPTIONS.keys).tap do |order|
      order.transform_values! { |v| { order: v }.merge(unmapped_type: :long) }
    end
  end

  def permitted_attributes
    self.class::PERMITTED_ATTRIBUTES
  end
end
