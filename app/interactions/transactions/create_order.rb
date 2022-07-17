class Transactions::CreateOrder < ApplicationInteraction
  integer :amount
  string :title, default: nil
  integer :purchasable, default: nil
  record :buyer, class: "ApplicationRecord"
  record :seller, class: "ApplicationRecord"
  record :dropzone

  validates :amount, :buyer, :seller, :dropzone, presence: true

  steps :create_order,
        :create_transactions,
        :update_credits,
        :confirm_order,
        # Return
        :order

  # Create events
  success do
    compose(
      ::Activity::CreateEvent,
      access_level: :system,
      access_context: access_context,
      resource: order,
      action: :created,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "Order ##{order.id} created with a total value of #{amount}"
    )
  end

  error do
    compose(
      ::Activity::CreateEvent,
      access_level: :system,
      level: :error,
      access_context: access_context,
      resource: receipt,
      action: :confirmed,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "Failed to create order of value #{amount}",
      details: errors.full_messages.join(", ")
    )
  end

  private
    def create_order
      @order = Order.create(
        title: title,
        dropzone: dropzone,
        seller: seller,
        buyer: buyer,
        amount: total_cost,
        state: :pending
      )
    end

    def confirm_order
      compose(
        ::Transactions::Confirm,
        receipt: @order.receipts.first,
        access_context: access_context
      )
    end

    def total_cost
      amount
    end

    def order_title
      case purchasable
      when Slot
        "Slot on Load #{purchasable.load.load_number}"
      when TicketType
        "#{purchasable.name} ticket"
      when DropzoneUser
        "Funds added to account"
      when Pack
        "packjob"
      else
        errors.add(:purchasable, "Not a valid type")
      end
    end

    def item_name
      (amount < 0 ? "Withdrawal" : "Deposit").to_s
    end
end
