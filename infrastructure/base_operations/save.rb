# frozen_string_literal: true

module BaseOperations::Save
  def save_record!
    record.save!
  end

  def mutate_record_call!
    return validation_fail unless form_valid?

    assign_attributes
    return validation_fail unless record_valid?

    save_record!

    return yield if block_given?

    success(record: record)
  end
end
