# frozen_string_literal: true

# One person can only hold one slot on a load (BUG-021). Duplicates created by concurrent requests are removed first,
# keeping the oldest slot of each pair; the removed ids are printed so they can be recovered from the log.
class AddUniqueIndexToSlotsOnLoadAndDropzoneUser < ActiveRecord::Migration[8.1]
  INDEX = "index_slots_on_load_id_and_dropzone_user_id"

  def up
    remove_duplicate_slots

    add_index :slots, [:load_id, :dropzone_user_id], unique: true, where: "dropzone_user_id IS NOT NULL", name: INDEX
  end

  def down
    remove_index :slots, name: INDEX
  end

  private

  def remove_duplicate_slots
    duplicate_ids = select_values(<<~SQL.squish).map(&:to_i)
      SELECT id FROM (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY load_id, dropzone_user_id ORDER BY created_at, id) AS position
        FROM slots
        WHERE dropzone_user_id IS NOT NULL
      ) ranked
      WHERE position > 1
    SQL

    say "Removing #{duplicate_ids.size} duplicate slot(s): #{duplicate_ids.inspect}"
    return if duplicate_ids.empty?

    ids = duplicate_ids.join(",")
    # Tandem passenger slots belong to the slot that is removed with them
    passenger_slot_ids = select_values("SELECT passenger_slot_id FROM slots WHERE id IN (#{ids}) AND passenger_slot_id IS NOT NULL").map(&:to_i)

    execute "DELETE FROM slot_extras WHERE slot_id IN (#{ids})"
    execute "DELETE FROM slots WHERE id IN (#{ids})"
    return if passenger_slot_ids.empty?

    say "Removing #{passenger_slot_ids.size} passenger slot(s) of those: #{passenger_slot_ids.inspect}"
    execute "DELETE FROM slots WHERE id IN (#{passenger_slot_ids.join(',')}) AND id NOT IN (SELECT passenger_slot_id FROM slots WHERE passenger_slot_id IS NOT NULL)"
  end
end
