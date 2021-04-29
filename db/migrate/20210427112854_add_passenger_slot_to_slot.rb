class AddPassengerSlotToSlot < ActiveRecord::Migration[6.1]
  def change
    add_reference :slots, :passenger_slot, null: true, foreign_key: { to_table: :slots }
  end
end
