class Manifest::FinalizeLoad < ApplicationInteraction
  integer :load
  validates :load, presence: true

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
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "#{access_context.subject.user.name} finalized load ##{load.load_number}"
    )
  end

  def save
    errors.merge!(load.errors) unless load.save
  end

  def mark_as_landed
    load.assign_attributes(state: :landed, is_open: false)
  end

  def finalize_orders
    load.slots.each do |slot|
      compose(
        ::Transactions::Confirm,
        receipt: slot.order.receipts.first,
        access_context: access_context,
      )
    end
  end
end
