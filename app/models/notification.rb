# frozen_string_literal: true

# == Schema Information
#
# Table name: notifications
#
#  id                :bigint           not null, primary key
#  message           :string
#  received_by_id    :bigint           not null
#  sent_by_id        :bigint
#  resource_type     :string
#  resource_id       :bigint
#  notification_type :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  is_seen           :boolean          default(FALSE)
#
class Notification < ApplicationRecord
  belongs_to :received_by, class_name: "DropzoneUser"
  belongs_to :sent_by, class_name: "DropzoneUser", optional: true
  belongs_to :resource, polymorphic: true

  enum notification_type: { :system => 0, :packjob_pending_confirm => 1, :packjob_confirmed => 2, :rig_pending_inspection => 3, :boarding_call => 4, :user_manifested => 5, :credits_updated => 6, :rig_inspection_completed => 7, :rig_inspection_requested => 8, :membership_updated => 9, :boarding_call_canceled => 10, :permission_granted => 11, :permission_revoked => 12, :publication_requested => 13 }

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
          "title" => received_by.dropzone.name,
        }
      )
    end
  end
end
