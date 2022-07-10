class Event < ApplicationRecord
  belongs_to :resource, polymorphic: true, optional: true
  belongs_to :dropzone_user, optional: true
  belongs_to :dropzone

  enum level: [
    :debug,
    :info,
    :error,
  ]

  enum access_level: [
    :user,
    :admin
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
    level ||= :info
  end
end
