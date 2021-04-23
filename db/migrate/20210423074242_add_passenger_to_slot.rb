class AddPassengerToSlot < ActiveRecord::Migration[6.1]
  def change
    add_reference :slots, :passenger, null: true, foreign_key: true
  end
end
