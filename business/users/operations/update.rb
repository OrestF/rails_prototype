# frozen_string_literal: true

class Users::Operations::Update < BaseOperation
  def call
    build_form

    mutate_record_call!
  end

  private

  def form_class
    Users::Forms::Update
  end
end
