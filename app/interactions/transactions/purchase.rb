# frozen_string_literal: true

class Transactions::Purchase < ApplicationInteraction
  record :purchasable, class: "ApplicationRecord", default: nil
  object :buyer, class: [::Dropzone, ::DropzoneUser]
  object :seller, class: [::Dropzone, ::DropzoneUser]

  validates :buyer, :seller, presence: true

  steps :create_order,
        :create_transactions,
        :update_credits,
        :refund_if_tandem,
        :save

  # Create events
  success do
    compose(
      ::Activity::CreateEvent,
      access_level: :system,
      access_context: access_context,
      resource: @order,
      action: :created,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "#{name_of(:buyer, buyer)} purchased #{item_name}"
    )
  end

  error do
    compose(
      ::Activity::CreateEvent,
      access_level: :system,
      level: :error,
      access_context: access_context,
      action: :confirmed,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "#{name_of(:buyer, buyer)} failed to purchase #{item_name}",
      details: errors.full_messages.join(", ")
    )
  end

  def create_order
    @order = Order.create(
      title: order_title,
      dropzone: access_context.dropzone,
      item: purchasable,
      seller: seller,
      buyer: buyer,
      amount: total_cost,
      state: :pending
    )
  end

  def save
    errors.merge!(@order.errors) unless @order.save
    @order
  end

  def refund_if_tandem
    return unless is_tandem?
    compose(
      Transactions::Refund,
      order: @order,
      access_context: access_context
    )
  end

  def update_credits
    seller.increment!(:credits, total_cost)
    buyer.decrement!(:credits, total_cost)
  end

  def create_transactions
    # Create a receipt
    receipt = Receipt.create(
      amount_cents: total_cost * 100,
      order: @order
    )
    errors.merge!(receipt.errors) unless receipt.valid?

    # Create a transaction for the seller
    seller_transaction = Transaction.create(
      receipt: receipt,
      amount: total_cost,
      message: "#{name_of(:buyer, buyer)} bought #{item_name}",
      sender: buyer,
      receiver: seller,
      status: :reserved,
      transaction_type: :sale
    )
    errors.merge!(seller_transaction.errors) unless seller_transaction.valid?

    # Create a transaction for the buyer
    buyer_transaction = Transaction.create(
      receipt: receipt,
      amount: -1 * total_cost,
      message: "$#{total_cost} for #{item_name}",
      sender: seller,
      receiver: buyer,
      status: :reserved,
      transaction_type: :purchase
    )
    errors.merge!(seller_transaction.errors) if seller_transaction.errors.any?
    errors.merge!(buyer_transaction.errors) if buyer_transaction.errors.any?
  end

  protected
    def is_tandem?
      case purchasable
      when Slot
        purchasable.ticket_type.is_tandem?
      when TicketType
        purchasable.is_tandem?
      else
        false
      end
    end

    def total_cost
      case purchasable
      when Slot
        purchasable.cost
      when TicketType
        purchasable.cost
      when Pack
        # FIXME: Should be defined on the packjob
        10
      else
        errors.add(:purchasable, "Not a valid type")
      end
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
      case purchasable
      when Slot
        ([
          purchasable.ticket_type.name
        ] + (purchasable.extras || []).map(&:name)).join(" + ")
      when TicketType
        "a #{purchasable.name} ticket"
      when DropzoneUser
        "an account update"
      when Pack
        "packjob"
      else
        errors.add(:purchasable, "Not a valid type")
      end
    end

    def name_of(buyer_or_seller, entity)
      case entity
      when Dropzone
      when User
        buyer.name
      when DropzoneUser
        buyer.user.name
      else
        errors.add(buyer_or_seller, "not a valid #{buyer_or_seller}")
      end
    end
end
