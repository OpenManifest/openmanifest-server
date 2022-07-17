# frozen_string_literal: true

require "active_interaction"

class Manifest::CancelLoad < ApplicationInteraction
  record :load
  validates :load, presence: true

  steps :mark_as_cancelled,
        :refund_orders,
        :save,
        :load

  # Create events
  success do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      resource: load,
      action: :deleted,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "#{access_context.subject.user.name} cancelled load ##{load.load_number}"
    )
  end

  def save
    errors.merge!(load.errors) unless load.save
    load.reload
  end

  def mark_as_cancelled
    load.assign_attributes(state: :cancelled, is_open: false)
  end

  def refund_orders
    load.slots.each do |slot|
      compose(
        ::Transactions::Refund,
        order: slot.order,
        access_context: access_context,
      )
    end
  end
end
