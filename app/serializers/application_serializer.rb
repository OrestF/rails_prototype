# frozen_string_literal: true

class ApplicationSerializer < Blueprinter::Base
  identifier :id

  def self.attachment_fields(field_name)
    field field_name do |record, _options|
      BlobSerializer.render_as_hash(record.send(field_name).includes([:blob]).map(&:blob))
    end
  end

  def self.conditional_relation(rel_name, record, current_user)
    if current_user&.customer? && record.booking.owner != current_user
      current_user.send(record.class.name.underscore.pluralize).include?(record) ? record.send(rel_name) : nil
    else
      record.send(rel_name)
    end
  end

  def self.mute_string(string)
    ApplicationHelper.mute_string(string)
  end
end
