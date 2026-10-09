# frozen_string_literal: true

class Manifest::FinalizeLoad < ApplicationInteraction
  record :load
  validates :load, presence: true

  steps :check_transition,
        :finalize_orders,
        :mark_as_landed,
        :load

  # Create events
  success do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      resource: load,
      action: :confirmed,
      access_level: :admin,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "#{access_context.user.name} finalized load ##{load.load_number}"
    )
  end

  def check_transition
    return if load.can_mark_as_landed?

    errors.add(:base, "Load ##{load.load_number} can't land, it is #{load.state.humanize.downcase}")
  end

  # The state machine counts the jumps and saves the load
  def mark_as_landed
    load.assign_attributes(is_open: false)
    errors.merge!(load.errors) unless load.mark_as_landed
  end

  def finalize_orders
    # Passenger slots have no order of their own: their jumper's order covers them
    load.slots.includes(order: :receipts).each do |slot|
      receipt = slot.order&.receipts&.first
      next unless receipt

      compose(
        ::Transactions::Confirm,
        receipt: receipt,
        access_context: access_context,
      )
    end
  end
end
