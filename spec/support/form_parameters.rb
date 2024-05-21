# frozen_string_literal: true

def render_form_parameters(form_class, except: [], &block)
  (form_class::PERMITTED_ATTRIBUTES - except).each do |attr|
    parameter attr, required: form_class::REQUIRED_ATTRIBUTES.include?(attr)
  end

  yield if block
end
