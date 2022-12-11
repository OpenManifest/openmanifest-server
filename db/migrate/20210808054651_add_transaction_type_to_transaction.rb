# frozen_string_literal: true

class AddTransactionTypeToTransaction < ActiveRecord::Migration[6.1]
  def change
    add_column :transactions, :transaction_type, :integer
    add_index :transactions, :transaction_type
    remove_column :transactions, :dropzone_user_id
    remove_column :transactions, :slot_id
  end
end
