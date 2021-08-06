# frozen_string_literal: true

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
#  is_seen           :boolean          default(FALSE)
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
    :credits_updated,
    :rig_inspection_completed,
    :rig_inspection_requested,
    :membership_updated,
    :boarding_call_canceled,
  ]

  after_create :send_async!

  def send_async!
    # Send async
    NotifyJob.perform_later(id)
  end

  def send!
    if received_by.user.push_token.present?
      HTTParty.post(
        "https://exp.host/--/api/v2/push/send",
        body: {
          "to" => received_by.user.push_token,
          "body" => message,
          "title" => received_by.dropzone.name
        }
      )
    end
  end
end
