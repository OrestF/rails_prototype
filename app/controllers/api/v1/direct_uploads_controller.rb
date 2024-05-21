# frozen_string_literal: true

class Api::V1::DirectUploadsController < Api::V1::BaseController
  skip_before_action :verify_class, only: %i[create destroy]
  skip_before_action :verify_record, only: [:destroy]

  def create
    operation_response(
      DirectUploads::Operations::Create.call(record_params: record_params),
      serializer: DirectUploadSerializer,
      root: :direct_upload
    )
  end

  def destroy
    operation_response(
      DirectUploads::Operations::Destroy.call(blob: blob)
    )
  end

  private

  def blob
    @blob ||= ActiveStorage::Blob.find_signed(params[:id])
  end

  def record_class_key
    :file
  end
end
