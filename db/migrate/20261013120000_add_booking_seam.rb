# frozen_string_literal: true

# P7.17 (GENERALISATION §7 "Dates", §17): what a booking needs of the manifest. A load keeps when it left and when it landed
# (set by its state machine), a slot can be paid already (the escort's ticket was charged to the guest), and a ticket of an
# escort has always been. Reversible; existing completed loads get their last change as the time they landed.
class AddBookingSeam < ActiveRecord::Migration[8.1]
  def up
    add_column :loads, :departed_at, :datetime
    add_column :loads, :completed_at, :datetime
    add_column :slots, :prepaid, :boolean, null: false, default: false

    # 2 departed, 3 completed
    execute "UPDATE loads SET departed_at = updated_at WHERE state IN (2, 3)"
    execute "UPDATE loads SET completed_at = updated_at WHERE state = 3"
    # A tandem's slots were never charged to the member (charged and refunded in one go): they are prepaid
    execute <<~SQL.squish
      UPDATE slots SET prepaid = TRUE
      FROM ticket_types WHERE slots.ticket_type_id = ticket_types.id AND ticket_types.requires_escort
    SQL
  end

  def down
    remove_column :slots, :prepaid
    remove_column :loads, :completed_at
    remove_column :loads, :departed_at
  end
end
