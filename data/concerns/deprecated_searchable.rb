# frozen_string_literal: true

class Searchable < Module
  # rubocop:disable Lint/MissingSuper
  def initialize(search_params:)
    define_method(:search_params) { search_params }
  end
  # rubocop:enable Lint/MissingSuper

  # rubocop:disable Metrics/AbcSize
  def extended(base)
    base.class_eval do
      def self.searchable_callbacks
        # For some reason, this doesn't work as stub in specs
        return :inline if Rails.env.test?

        :async
      end

      scope :search_import, -> { unscope(where: :deactivated_at) }

      searchkick(callbacks: searchable_callbacks, **search_params) unless respond_to?(:searchkick_index)

      def search_data
        base_search_fields.merge!(search_fields)
      end

      def self.scope_indexed?(records)
        records.unscoped.count == records.search_index.total_docs
      end

      def self.reindex_if_needed(records)
        return if scope_indexed?(records)

        search_index.send(:full_reindex, records)
      end

      def base_search_fields
        {
          organization_id: try(:organization_id),
          created_at: try(:created_at),
          updated_at: try(:updated_at)
        }
      end
    end
  end
  # rubocop:enable Metrics/AbcSize
end
