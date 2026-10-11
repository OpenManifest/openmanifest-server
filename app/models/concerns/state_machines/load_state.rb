# frozen_string_literal: true

# The life of a load. All changes of Load#state go through these events (Manifest::UpdateLoad maps the state the client
# asks for to an event), so a landed load cannot be called again, a cancelled one cannot take off, and the jump counters
# move exactly once per transition.
#
#   open ──dispatch──▶ boarding_call ──take_off──▶ in_flight ──mark_as_landed──▶ landed
#     │ ▲                  │ ▲                                                      │
#     │ └──────reopen──────┴─┴──────────────────────reopen───────────────────────────┘ (also from cancelled)
#     └──cancel──▶ cancelled (also from boarding_call)
module StateMachines::LoadState
  extend ActiveSupport::Concern

  included do
    state_machine :state, initial: :open do
      after_transition any => :cancelled do |record|
        record.slots.each do |slot|
          next if slot.dropzone_user.blank?

          Notification.create(
            message: "Load ##{record.load_number} call canceled",
            resource: record,
            received_by: slot.dropzone_user,
            notification_type: :boarding_call_canceled
          )
        end
      end

      after_transition any => :boarding_call do |record|
        record.slots.each do |slot|
          next if slot.dropzone_user.blank?

          Notification.create(
            message: "Load ##{record.load_number} take off at #{record.dispatch_at.in_time_zone(record.plane.dropzone.time_zone).strftime('%H:%M')}",
            resource: record,
            received_by: slot.dropzone_user,
            notification_type: :boarding_call
          )
        end
      end

      # The jumps count when the load lands, and are taken back when a landed load is reopened (BUG-026)
      after_transition any => :landed do |record|
        record.count_jumps!(1)
      end

      after_transition landed: any do |record|
        record.count_jumps!(-1)
      end

      # A boarding call needs a time
      event :dispatch do
        transition open: :boarding_call, if: ->(record) { record.dispatch_at.present? }
      end

      event :take_off do
        transition %i(open boarding_call) => :in_flight
      end

      event :mark_as_landed do
        transition %i(open boarding_call in_flight) => :landed
      end

      event :cancel do
        transition %i(open boarding_call) => :cancelled
      end

      event :reopen do
        transition %i(boarding_call in_flight landed cancelled) => :open
      end
    end
  end
end
