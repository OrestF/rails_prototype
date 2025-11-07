# frozen_string_literal: true

class BaseSearch < BaseAction
  include Pagy::Backend

  attr_reader :scope, :search_params, :paginate

  TEXT_SEARCH_KEY = :by_free_text
  SORT_PREFIX = 'sort_by'

  def call
    # reindex_if_needed
    return simple_search if permitted_search_params.blank?

    search_results
  end

  private

  # def reindex_if_needed
  #   return unless advanced?
  #
  #   scope.klass.reindex_if_needed(scope.klass.all)
  # end

  # rubocop:disable Layout/LineLength
  def permitted_search_params
    return {} if search_params.blank?
    return @permitted_search_params if defined?(@permitted_search_params)

    patch_free_text_search

    @permitted_search_params = (search_params.is_a?(ActionController::Parameters) ? search_params.permit!.to_h : search_params).slice(*permitted_attributes)
  end
  # rubocop:enable Layout/LineLength

  def patch_free_text_search
    # make by_search_query work as by_free_text
    if search_params[:by_free_text].present?
      search_params.delete(:by_search_query)
    elsif search_params[:by_search_query].present?
      search_params[:by_free_text] = search_params[:by_search_query]
    else
      search_params
    end
  end

  def search_results
    simple_search
    # return simple_search unless advanced?

    # optimized_advanced_search
  end

  # def advanced?
  #   Searchkick.models.include?(scope.klass)
  # end

  def advanced_query_param
    @advanced_query_param ||= search_params.delete(TEXT_SEARCH_KEY) || '*'
  end

  def simple_search(skip_sorting: false)
    apply_filters
    apply_sorting unless skip_sorting
    apply_pagination if paginate?

    @scope
  end

  def optimized_advanced_search
    apply_filters
    advanced_result_ids = scope.klass.search(
      advanced_query_param,
      misspellings: false,
      load: false,
      **advanced_params
    ).map(&:id)

    @scope = scope.where(id: advanced_result_ids)
    apply_sorting
    apply_pagination if paginate?

    scope
  end

  def advanced_params
    # limit advanced search only to simple search results
    ids_query = { where: { scope.klass.primary_key.to_sym => scope.ids } }
    params = advanced_search_extra_params
    params[:where] = ids_query[:where].merge(params[:where].to_h)
    params
  end

  def apply_filters
    @scope = scope.filter_collection(filter_params)
  end

  def apply_sorting
    @scope = scope.filter_collection(sort_params)
  end

  def apply_pagination
    before_pagination_count = @scope.count
    @scope = paginate_collection(scope, pagination_params)
    @scope.define_singleton_method(:before_pagination_count) { before_pagination_count }
    @scope
  end

  def filter_params
    permitted_search_params.except(TEXT_SEARCH_KEY).reject { |k, _v| k.to_s.start_with?(SORT_PREFIX) }
  end

  def sort_params
    permitted_search_params.except(TEXT_SEARCH_KEY).select { |k, _v| k.to_s.start_with?(SORT_PREFIX) }
  end

  def pagination_params
    { page: 1, per_page: 10 }.with_indifferent_access.merge!(search_params.slice(:page, :per_page))
  end

  def advanced_search_extra_params
    {}
  end

  def permitted_attributes
    self.class::PERMITTED_ATTRIBUTES
  end

  def paginate?
    @paginate
  end

  def paginate_collection(scope, options)
    if Pagy::VERSION.to_i >= 9
      pagy(scope, { page: options[:page], limit: options[:per_page] }).last
    else
      pagy(scope, { page: options[:page], items: options[:per_page] }).last
    end
  end
end
