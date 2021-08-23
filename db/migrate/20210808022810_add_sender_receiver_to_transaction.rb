class AddSenderReceiverToTransaction < ActiveRecord::Migration[6.1]
  def change
    add_reference :transactions, :sender, polymorphic: true, null: false
    add_reference :transactions, :receiver, polymorphic: true, null: false
  end
end
