# frozen_string_literal: true

class Transactions::CreateOrder < Transactions::Purchase
  # In cents; positive when the buyer pays the seller
  integer :amount_cents
  string :title, default: nil
  integer :purchasable, default: nil
  object :buyer, class: [::Dropzone, ::DropzoneUser]
  object :seller, class: [::Dropzone, ::DropzoneUser]
  record :dropzone

  validates :amount_cents, :buyer, :seller, :dropzone, presence: true
  validate :parties_belong_to_dropzone

  steps :check_balance,
        :create_order,
        :create_transactions,
        :update_credits,
        :confirm_order

  # Create events
  success do
    compose(
      ::Activity::CreateEvent,
      access_level: :system,
      level: :debug,
      access_context: access_context,
      resource: @order,
      action: :created,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "Order ##{@order.id} created with a total value of #{Money.new(amount_cents)}"
    )
  end

  error do
    compose(
      ::Activity::CreateEvent,
      access_level: :system,
      level: :error,
      access_context: access_context,
      # An event needs a resource: the failed order (if it got that far), else the dropzone
      resource: @order || dropzone,
      action: :confirmed,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "Failed to create order of value #{Money.new(amount_cents)}",
      details: errors.full_messages.join(", ")
    )
  end
  def create_order
    @order = Order.new(
      title: title,
      dropzone: dropzone,
      seller: seller,
      buyer: buyer,
      amount_cents: total_cents,
      state: :pending
    )
    errors.merge!(@order.errors) unless @order.save
  end

  def confirm_order
    compose(
      ::Transactions::Confirm,
      receipt: @order.receipts.first,
      access_context: access_context
    )
    @order
  end

  def total_cents
    amount_cents
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
    (amount_cents.negative? ? "Withdrawal" : "Deposit").to_s
  end

  # A member cannot pay more than they have, unless the dropzone allows negative credits. A step rather than a
  # validation: validations run again after the interaction, when the balance has already changed.
  def check_balance
    return unless buyer.is_a?(::DropzoneUser) && amount_cents.to_i.positive?
    return if dropzone&.allow_negative_credits? || (buyer.credits_cents || 0) >= amount_cents

    errors.add(:amount, "Not enough credits")
  end

  private

  # Whoever calls this interaction: credits only move between a dropzone and its own members
  def parties_belong_to_dropzone
    return if dropzone.blank?

    [buyer, seller].each do |party|
      belongs = party.is_a?(::Dropzone) ? party.id == dropzone.id : party.try(:dropzone_id) == dropzone.id
      errors.add(:base, "The buyer and the seller must be the dropzone or its members") unless belongs
    end
  end
end
