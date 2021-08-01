# frozen_string_literal: true

class AddTransactionToSlot < ActiveRecord::Migration[6.1]
  def change
    add_reference :slots, :transaction, null: true, foreign_key: true
  end
end
