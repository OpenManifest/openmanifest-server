# frozen_string_literal: true

class Manifest::FinalizeLoad < ApplicationInteraction
  record :load
  validates :load, presence: true

  steps :mark_as_landed,
        :finalize_orders,
        :save,
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

  def save
    errors.merge!(load.errors) unless load.save
  end

  def mark_as_landed
    load.assign_attributes(state: :landed, is_open: false)
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
