# frozen_string_literal: true

# The life of a load. All changes of Load#state go through these events (Manifest::UpdateLoad maps the state the client
# asks for to an event), so a completed load cannot be called again, a cancelled one cannot take off, and the jump counters
# move exactly once per transition.
#
#   open ──call──▶ boarding ──depart──▶ departed ──complete──▶ completed
#     │ ▲                  │ ▲                                                      │
#     │ └──────reopen──────┴─┴──────────────────────reopen───────────────────────────┘ (also from cancelled)
#     └──cancel──▶ cancelled (also from boarding)
module StateMachines::LoadState
  extend ActiveSupport::Concern

  included do
    state_machine :state, initial: :open do
      after_transition any => :cancelled do |record|
        record.slots.each do |slot|
          next if slot.membership.blank?

          Notification.create(
            message: "Load ##{record.load_number} call canceled",
            resource: record,
            received_by: slot.membership,
            notification_type: :boarding_canceled
          )
        end
      end

      after_transition any => :boarding do |record|
        record.slots.each do |slot|
          next if slot.membership.blank?

          Notification.create(
            message: "Load ##{record.load_number} take off at #{record.dispatch_at.in_time_zone(record.operator.time_zone).strftime('%H:%M')}",
            resource: record,
            received_by: slot.membership,
            notification_type: :boarding
          )
        end
      end

      # The jumps count when the load lands, and are taken back when a completed load is reopened (BUG-026)
      after_transition any => :completed do |record|
        record.count_jumps!(1)
      end

      after_transition completed: any do |record|
        record.count_jumps!(-1)
      end

      # A boarding call needs a time
      event :call do
        transition open: :boarding, if: ->(record) { record.dispatch_at.present? }
      end

      event :depart do
        transition %i(open boarding) => :departed
      end

      event :complete do
        transition %i(open boarding departed) => :completed
      end

      event :cancel do
        transition %i(open boarding) => :cancelled
      end

      event :reopen do
        transition %i(boarding departed completed cancelled) => :open
      end
    end
  end
end
