# frozen_string_literal: true

class BaseOperation < BaseAction
  attr_reader :form, :record, :record_params

  private

  def build_form
    @form = form_class.new(record_params, record: record)
  end

  def form_valid?
    form.validate
  end

  def assign_attributes
    record.assign_attributes(record_params)
  end

  def record_valid?
    return true if record.errors.none? && record.valid?

    false
  end

  def save_record
    record.save
  end

  def success(*args)
    response(:success, *args)
  end

  def validation_fail(args = {})
    form&.sync_errors

    response(args.delete(:status) || :validation_fail, args.merge!(record: record,
                                                                   record_params: record_params,
                                                                   errors: record.errors.messages))
  end

  def form_class
    raise 'Define form_class in child operation'
  end
end
