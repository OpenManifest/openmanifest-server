# frozen_string_literal: true

class AddIsDeletedToTicketTypes < ActiveRecord::Migration[6.1]
  def change
    add_column :ticket_types, :is_deleted, :boolean, default: false
  end
end
