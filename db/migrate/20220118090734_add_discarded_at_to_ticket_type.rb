# frozen_string_literal: true

class AddDiscardedAtToTicketType < ActiveRecord::Migration[6.1]
  def change
    add_column :ticket_types, :discarded_at, :datetime
    add_index :ticket_types, :discarded_at
  end
end
