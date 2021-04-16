# frozen_string_literal: true

class CreateTicketTypeExtras < ActiveRecord::Migration[6.1]
  def change
    create_table :ticket_type_extras do |t|
      t.references :ticket_type, null: false, foreign_key: true
      t.references :extra, null: false, foreign_key: true

      t.timestamps
    end
  end
end
