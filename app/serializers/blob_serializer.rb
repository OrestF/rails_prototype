# frozen_string_literal: true

class BlobSerializer < ApplicationSerializer
  identifier :signed_id
  fields :filename

  field :url do |blob, _options|
    next if blob.blank?

    if blob.service_name == 'amazon'
      blob.url(expires_in: 1.hour)
    else
      Rails.application.routes.url_helpers.rails_blob_url(blob)
    end
  end
end
