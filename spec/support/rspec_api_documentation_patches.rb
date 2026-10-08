# frozen_string_literal: true

require 'rspec_api_documentation/writers/open_api_writer'

module RspecApiDocumentation
  module Writers
    # Fix: YAML.load_file does not process ERB. Override load_config to use ERB.
    class OpenApiWriter
      private

      def load_config
        yml_path = "#{configurations_dir}/open_api.yml"

        return unless File.exist?(yml_path)

        YAML.safe_load(ERB.new(File.read(yml_path)).result)
      end
    end

    # Swagger 2.0 supports `collectionFormat` to describe how array query params
    # are serialized (e.g. `multi` for `?ids[]=1&ids[]=2`). The gem has no setting
    # for it, so we register one here.
    OpenApi::Parameter.add_setting :collectionFormat

    # Fix gem bug: opts[:value] can be nil when array parameters are declared
    # without an example value (e.g. `parameter :paxes, '...', type: :array`).
    # The gem calls opts[:value][0] unconditionally, causing NoMethodError.
    # Also adds `collectionFormat` passthrough for array parameters.
    # rubocop:disable Metrics/AbcSize
    module OpenApiIndexPatch
      def extract_parameter(opts)
        OpenApi::Parameter.new(
          name: opts[:name],
          in: opts[:in],
          description: opts[:description],
          required: opts[:required],
          type: opts[:type] || OpenApi::Helper.extract_type(opts[:value]),
          value: opts[:value],
          with_example: opts[:with_example],
          default: opts[:default]
        ).tap do |elem|
          if elem.type == :array
            elem.items = opts[:items] || OpenApi::Helper.extract_items(opts[:value]&.first, { minimum: opts[:minimum], maximum: opts[:maximum], enum: opts[:enum] })
            elem.collectionFormat = opts[:collection_format] if opts[:collection_format]
          else
            elem.minimum = opts[:minimum]
            elem.maximum = opts[:maximum]
            elem.enum    = opts[:enum]
          end
        end
      end
    end

    OpenApiIndex.prepend(OpenApiIndexPatch)
  end
  # rubocop:enable Metrics/AbcSize
end
