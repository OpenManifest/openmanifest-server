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

  enum :notification_type, {
    :system => 0, :packjob_pending_confirm => 1, :packjob_confirmed => 2, :rig_pending_inspection => 3,
    :boarding_call => 4, :user_manifested => 5, :credits_updated => 6, :rig_inspection_completed => 7, :rig_inspection_requested => 8, :membership_updated => 9, :boarding_call_canceled => 10, :permission_granted => 11, :permission_revoked => 12, :publication_requested => 13,
  }

  scope :seen, -> { where(is_seen: true) }
  scope :unseen, -> { where(is_seen: false) }

  after_create :send_async!

  def send_async!
    # Send async
    NotifyJob.perform_later(id)
  end

  EXPO_PUSH_URL = "https://exp.host/--/api/v2/push/send"

  # Sends the push notification through Expo (NotifyJob). Network errors and server errors are raised for the job to
  # retry; Expo answers with a ticket per message, and a token it does not know (DeviceNotRegistered: the app was
  # uninstalled, the token expired) is removed from the user, so nothing is sent to it again.
  def deliver
    token = received_by.user.push_token
    return if token.blank?

    response = HTTParty.post(
      EXPO_PUSH_URL,
      headers: { "Content-Type" => "application/json", "Accept" => "application/json" },
      body: { to: token, title: received_by.dropzone.name, body: message, data: { notificationId: id, type: notification_type } }.to_json
    )
    raise HTTParty::ResponseError, response if response.server_error?

    handle_ticket(token, response.parsed_response.is_a?(Hash) ? response.parsed_response["data"] : nil)
  end

  private

  def handle_ticket(token, ticket)
    return unless ticket.is_a?(Hash) && ticket["status"] == "error"

    if ticket.dig("details", "error") == "DeviceNotRegistered"
      User.where(push_token: token).update_all(push_token: nil)
    else
      Rails.logger.warn("Push notification #{id} not delivered: #{ticket['message']}")
    end
  end
end
