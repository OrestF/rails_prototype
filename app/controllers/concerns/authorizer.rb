# frozen_string_literal: true

module Authorizer
  extend ActiveSupport::Concern

  include Pundit::Authorization

  included do
    before_action :verify_record, except: %i[index new create]
    before_action :verify_class

    after_action :verify_pundit_authorization
  end

  private

  def verify_pundit_authorization
    if action_name == "index"
      verify_policy_scoped
    else
      verify_authorized
    end
  end

  def record_class
    controller_name.singularize.camelize.constantize
  end

  def scoped_collection
    policy_scope(record_class.all)
  end

  def record
    @record ||= scoped_collection.find(params[:id])
  end

  def verify_record
    @record_verified = true
    authorize_with_configs(record)
  end

  def verify_class
    authorize_with_configs(record_class) unless record_verified?
  end

  def record_verified?
    @record_verified
  end

  def authorize_with_configs(record, configs = {})
    policy = configs[:policy_class].presence || policy_class
    return true if policy.new(current_user, record, configs).send(:"#{action_name}?")

    raise Pundit::NotAuthorizedError, "You are not allowed to #{action_name.humanize.downcase} #{record_class.model_name.human}"
  end

  def policy_class
    "#{record_class}Policy".constantize
  end
end
