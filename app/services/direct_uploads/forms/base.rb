# frozen_string_literal: true

class DirectUploads::Forms::Base < BaseForm
  PERMITTED_ATTRIBUTES = %i[filename byte_size checksum content_type metadata].freeze
  REQUIRED_ATTRIBUTES = %i[filename byte_size checksum content_type].freeze
end
