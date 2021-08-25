# frozen_string_literal: true

class AddReceiptToTransaction < ActiveRecord::Migration[6.1]
  def change
    add_reference :transactions, :receipt, null: false, foreign_key: true
  end
end
