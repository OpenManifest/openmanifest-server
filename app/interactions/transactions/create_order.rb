require 'active_interaction'

class Transactions::CreateOrder < Transactions::Purchase
  include ActiveInteraction::Extras::Transaction
  run_in_transaction!

  integer :amount
  string :title
  record :buyer, class: 'ApplicationRecord'
  record :seller, class: 'ApplicationRecord'
  record :dropzone

  validates :amount, :title, :buyer, :seller, :dropzone, presence: true

  def execute
    create_order
    create_transactions
    update_credits
    confirm_order

    @order
  end

  private
    def create_order
      @order = Order.create(
        title: title,
        dropzone: dropzone,
        seller: seller,
        buyer: buyer,
        amount: total_cost,
        state: :pending,
      )
    end

    def confirm_order
      compose(Confirm, receipt: @order.receipts.first)
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
      "#{amount < 0 ? "Withdrawal" : "Deposit"}"
    end
end
