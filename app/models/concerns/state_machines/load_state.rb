# frozen_string_literal: true

module StateMachines::LoadState
  extend ActiveSupport::Concern

  included do
    state_machine :state, initial: :open do
      after_transition any => :mark_as_landed do
      end

      after_transition any => :cancelled do |record|
        record.slots.each do |slot|
          next unless slot.dropzone_user.present?

          Notification.create(
            message: "Load ##{load_number} call canceled",
            resource: self,
            received_by: slot.dropzone_user,
            notification_type: :boarding_call_canceled
          )
        end
      end

      after_transition any => :boarding_call do |record|
        record.slots.each do |slot|
          next unless slot.dropzone_user.present?

          Notification.create(
            message: "Load ##{load_number} take off at #{dispatch_at.in_time_zone(plane.dropzone.time_zone).strftime('%H:%M')}",
            resource: self,
            received_by: slot.dropzone_user,
            notification_type: :boarding_call
          )
        end
      end

      event :dispatch do
        transition open: :boarding_call
      end

      event :take_off do
        transition any => :in_flight
      end

      event :mark_as_landed do
        transition any => :landed
      end

      event :cancel do
        transition any => :cancelled
      end

      event :reopen do
        transition any => :open
      end
    end
  end
end
