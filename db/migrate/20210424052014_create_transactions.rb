# frozen_string_literal: true

class CreateTransactions < ActiveRecord::Migration[6.1]
  def change
    create_table :transactions do |t|
      t.references :dropzone_user, null: false, foreign_key: true
      t.references :slot, null: true, foreign_key: true
      t.integer :status, index: true
      t.float :amount

      t.timestamps
    end
  end
end
