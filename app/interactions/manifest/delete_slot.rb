# frozen_string_literal: true

class Manifest::DeleteSlot < ApplicationInteraction
  record :slot

  steps :authorize_action,
        :remove_passenger_slot,
        :refund_transactions,
        :cancel_order,
        :delete_slot

  # Create events
  success do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      resource: slot,
      action: :deleted,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: if is_self?
                 "#{access_context.subject.user.name} took themselves off load ##{slot.load.load_number}"
               else
                 "#{access_context.subject.user.name} removed #{slot.dropzone_user.user.name} from load ##{slot.load.load_number}"
               end

    )
  end

  error do
    compose(
      ::Activity::CreateEvent,
      level: :error,
      access_context: access_context,
      resource: slot,
      action: :deleted,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: if is_self?
                 "#{access_context.subject.user.name} failed to take themselves off load ##{load.load_number}"
               else
                 "#{access_context.subject.user.name} failed to remove a slot on load ##{load.load_number}"
               end,
      details: errors.full_messages.join(", ")
    )
  end

  def remove_passenger_slot
    slot.passenger_slot.destroy if slot.has_passenger?
  end

  def refund_transactions
    compose(
      ::Transactions::Refund,
      order: slot.order,
      access_context: access_context
    )
  end

  def cancel_order
    slot.order.update(state: :cancelled)
  end

  def delete_slot
    slot.destroy
    slot
  end


  def is_self?
    access_context.subject.id == slot.dropzone_user_id
  end

  def authorize_action
    if slot.load.has_landed?
      errors.add(:base, "You can't take slots off a load that has landed")
    elsif is_self? && !access_context.can?(:deleteSlot)
      errors.add(:base, "You cant take yourself off the load")
    elsif !is_self? && !access_context.can?(:deleteUserSlot)
      errors.add(:base, "You cant take somebody else off the load")
    end
  end
end
