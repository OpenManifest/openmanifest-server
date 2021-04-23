class Notification < ApplicationRecord
  belongs_to :received_by, class_name: "DropzoneUser"
  belongs_to :sent_by, class_name: "DropzoneUser", optional: true
  belongs_to :resource, polymorphic: true

  enum notification_type: [
    :system,
    :packjob_pending_confirm,
    :packjob_confirmed,
    :rig_pending_inspection,
    :boarding_call
  ]
end
