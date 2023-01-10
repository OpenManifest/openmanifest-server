# frozen_string_literal: true

class Activity::Event < ApplicationRecord
  self.table_name = "events"

  belongs_to :resource, polymorphic: true, optional: true
  belongs_to :created_by, foreign_key: :dropzone_user_id, optional: true, class_name: "DropzoneUser"
  belongs_to :dropzone

  enum level: { :debug => 0, :info => 1, :error => 2 }

  enum access_level: { :user => 0, :admin => 1, :system => 2 }

  enum action: { :assigned => 0, :created => 1, :updated => 2, :confirmed => 3, :deleted => 4 }

  # Default to info if no level is set
  before_validation do
    assign_attributes(
      level: level || :info,
      access_level: access_level || :user
    )
  end
end
