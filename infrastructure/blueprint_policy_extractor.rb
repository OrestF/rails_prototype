# frozen_string_literal: true
require 'blueprinter/extractors/auto_extractor'

class BlueprintPolicyExtractor < Blueprinter::AutoExtractor
  # validate each association to be within policy scope
  class PolicyPublicSendExtractor < Blueprinter::PublicSendExtractor
    def extract(field_name, object, local_options, options = {})
      # return if attachment or not an association
      return super if object.is_a?(ActiveStorage::Attached) || !object.class.reflect_on_association(field_name)

      object.public_send(field_name).then do |scope_or_record|
        user = options[:current_user] || Current.user
        if scope_or_record.is_a?(Enumerable)
          # apply policy to scope if it is a scope
          Pundit.policy_scope!(user, scope_or_record)
        elsif scope_or_record.nil?
          super
        elsif Pundit.policy_scope!(user,
                                   scope_or_record.class.where(scope_or_record.class.primary_key => scope_or_record)).exists?
          # return nil unless record is within policy scope
          scope_or_record
        end
      end
    rescue StandardError => _e
      super
    end
  end

  def initialize
    super

    @public_send_extractor = PolicyPublicSendExtractor.new
  end
end
