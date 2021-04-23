class AddIsTandemToTicketTypes < ActiveRecord::Migration[6.1]
  def change
    add_column :ticket_types, :is_tandem, :boolean, default: false
  end
end
