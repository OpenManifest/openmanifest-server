# == Schema Information
#
# Table name: notifications
#
#  id                :integer          not null, primary key
#  message           :string
#  received_by_id    :integer          not null
#  sent_by_id        :integer
#  resource_type     :string
#  resource_id       :integer
#  notification_type :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class Notification < ApplicationRecord
  belongs_to :received_by, class_name: "DropzoneUser"
  belongs_to :sent_by, class_name: "DropzoneUser", optional: true
  belongs_to :resource, polymorphic: true

  enum notification_type: [
    :system,
    :packjob_pending_confirm,
    :packjob_confirmed,
    :rig_pending_inspection,
    :boarding_call,
    :user_manifested,
    :funds_added,
    :rig_inspection_completed,
    :membership_updated
  ]
end
