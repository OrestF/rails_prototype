# frozen_string_literal: true

class DirectUploads::Operations::Destroy < BaseOperation
  include Operations::Authorize

  def call
    response(:skipped, consider_success: true) if blob.blank?

    find_record
    authorize! && remove_attachments if record.present?

    remove_blob
    response(:success, record: {})
  end

  private

  attr_reader :blob

  def find_record
    @record = blob.attachments.first&.record
  end

  def remove_attachments
    blob.attachments.each(&:purge)
  end

  def remove_blob
    blob.purge
  end
end
