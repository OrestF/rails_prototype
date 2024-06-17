# frozen_string_literal: true

require 'oj'

begin
  require Rails.root.join('infrastructure/blueprint_policy_extractor').to_s
rescue LoadError
  # Handle the case where the file is not found (optional)
  puts "BlueprintPolicyExtractor not found"
end

Blueprinter.configure do |config|
  config.generator = Oj
  config.extractor_default = BlueprintPolicyExtractor if defined?(BlueprintPolicyExtractor)
  config.if = ->(field_name, obj, _options) do
    return true if (policy_class = "#{obj.class.name}Policy".safe_constantize).blank?
    return true unless policy_class::RESTRICTED_ATTRIBUTES.key?(field_name.to_sym)

    policy_class.new(Current.user, obj).read_attr?(field_name.to_sym)
  end
end
