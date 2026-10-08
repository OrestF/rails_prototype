# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  include ActionScope # by_*/sort_by_* scopes + options_for_search
  include Readymade::Model::Filterable # filter_collection, used by BaseSearch

  # action_scope reads the schema when a model class is loaded, and devise_for loads User while routes are drawn.
  # In production that happens on every boot, db:create/db:prepare included, so skip the scopes while there is
  # no database yet - the same way action_scope itself skips them while migrations are pending.
  def self.action_scope(...)
    super
  rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished
    nil
  end
end
