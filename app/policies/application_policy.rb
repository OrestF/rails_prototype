# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record, :configs, :organization

  # =================================

  RESTRICTED_ATTRIBUTES = {}.freeze

  # example
  # UserPolicy::RESTRICTED_ATTRIBUTES = {
  #   buyer_min_bid: %w[supplier buyer],
  #   buyer_max_bid: %w[buyer],
  #   min_bid: %w[supplier],
  #   max_bid: %w[supplier].flatten
  # }.freeze

  def read_attr?(field)
    return false unless show?
    # if attr is not defined in FIELDS, it is readable by default
    return true if self.class::RESTRICTED_ATTRIBUTES[field].nil?

    self.class::RESTRICTED_ATTRIBUTES[field].include?(user.role)
  end

  # =================================

  def initialize(user, record, configs = {})
    @user = user
    @record = record
    @configs = configs

    @organization = user.try(:organization)
  end

  def index?
    user.can?(resource_name, :read)
  end

  def show?
    user.can?(resource_name, :read) { scoped_record? }
  end

  def create?
    user.can?(resource_name, :create)
  end

  def update?
    user.can?(resource_name, :update) { scoped_record? }
  end

  def destroy?
    user.can?(resource_name, :delete) { scoped_record? }
  end

  private

  def resolved_scope
    Pundit.policy_scope!(user, record.class.all)
  end

  def scoped_record?
    resolved_scope.exists?(id: record)
  end

  def resource_name
    self.class.name.gsub('Policy', '').underscore.tr('/', '_').to_sym
  end

  class Scope
    attr_reader :user, :scope, :organization

    def initialize(user, scope)
      @user = user
      @scope = scope
      @organization = user.try(:organization)
    end

    def resolve
      scope
    end

    def policy_scope(scope)
      Pundit.policy_scope!(user, scope)
    end
  end
end
