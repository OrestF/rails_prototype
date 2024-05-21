# frozen_string_literal: true

class DirectUploads::Operations::Create < BaseOperation
  LINK_EXPIRATION_HOURS = 1

  def call
    return validation_fail unless form_valid?

    build_record
    update_record_key
    generate_signed_url

    response(:success, record: @signed_url_data)
  end

  private

  def form_class
    DirectUploads::Forms::Base
  end

  def build_record
    # Do not use record_params.slice or record_params.to_h.deep_symbolize_keys
    # because it causes wrong number of arguments error
    @record = ActiveStorage::Blob.create_before_direct_upload!(filename: record_params[:filename],
                                                               byte_size: record_params[:byte_size],
                                                               checksum: record_params[:checksum],
                                                               content_type: record_params[:content_type],
                                                               metadata: record_params[:metadata].presence || {})
  end

  def update_record_key
    @record.update_attribute(:key, record_key)
  end

  def generate_signed_url
    @signed_url_data = {
      url: @record.service_url_for_direct_upload(expires_in: LINK_EXPIRATION_HOURS.hours),
      headers: @record.service_headers_for_direct_upload,
      signed_id: @record.signed_id
    }
  end

  def record_key
    "uploads/#{SecureRandom.uuid}"
  end
end
