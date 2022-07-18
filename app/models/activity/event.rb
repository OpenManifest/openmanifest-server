# frozen_string_literal: true

class Activity::Event < ApplicationRecord
  self.table_name = "events"
  belongs_to :resource, polymorphic: true, optional: true
  belongs_to :created_by, foreign_key: :dropzone_user_id, optional: true, class_name: "DropzoneUser"
  belongs_to :dropzone

  enum level: [
    :debug,
    :info,
    :error,
  ]

  enum access_level: [
    :user,
    :admin,
    :system
  ]

  enum action: [
    :assigned,
    :created,
    :updated,
    :confirmed,
    :deleted,
  ]

  # Default to info if no level is set
  before_validation do
    assign_attributes(level: level || :info)
  end
end
