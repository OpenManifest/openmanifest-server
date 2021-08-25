# frozen_string_literal: true

class AddTransactionTypeToTransaction < ActiveRecord::Migration[6.1]
  def change
    add_column :transactions, :transaction_type, :integer, index: true
    remove_column :transactions, :dropzone_user_id
    remove_column :transactions, :slot_id
  end
end
