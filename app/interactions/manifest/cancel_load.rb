# frozen_string_literal: true

require "active_interaction"

class Manifest::CancelLoad < ApplicationInteraction
  record :load
  validates :load, presence: true

  steps :check_transition,
        :refund_orders,
        :cancel,
        :load

  # Create events
  success do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      resource: load,
      access_level: :user,
      action: :deleted,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "#{access_context.user.name} cancelled load ##{load.load_number}"
    )
  end

  def check_transition
    return if load.can_cancel?

    errors.add(:base, "Load ##{load.load_number} can't be cancelled, it is #{load.state.humanize.downcase}")
  end

  def cancel
    load.assign_attributes(is_open: false)
    errors.merge!(load.errors) unless load.cancel
    load.reload
  end

  def refund_orders
    load.slots.each do |slot|
      # Passenger slots have no order of their own
      next unless slot.order

      compose(
        ::Transactions::Refund,
        order: slot.order,
        access_context: access_context,
      )
    end
  end
end
