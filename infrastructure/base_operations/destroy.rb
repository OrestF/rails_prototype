# frozen_string_literal: true

module BaseOperations::Destroy
  def destroy_record_call!
    return validation_fail unless form_valid?

    destroy_record!

    return yield if block_given?

    success(record: record)
  end
  alias call destroy_record_call!
  alias call! destroy_record_call!

  def destroy_record!
    record.destroy!
  end

  def form_class
    BaseForms::Destroy
  end
end
