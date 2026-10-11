# frozen_string_literal: true

# Loads carry their dropzone (they reached it through the plane) and the day they belong to in the dropzone's time zone,
# and their number is unique per dropzone and day (BUG-022, BUG-050). Duplicate numbers (the old number was today's count
# of kept loads plus one, so archiving a load repeated one) are renumbered: the oldest load of a number keeps it, later
# ones get the next free numbers of that day. Every change is printed.
class AddDropzoneAndLoadDateToLoads < ActiveRecord::Migration[8.1]
  INDEX = "index_loads_on_dropzone_id_and_load_date_and_load_number"

  def up
    add_reference :loads, :dropzone, foreign_key: true, index: false
    add_column :loads, :load_date, :date

    execute "UPDATE loads SET dropzone_id = planes.dropzone_id FROM planes WHERE planes.id = loads.plane_id"
    backfill_load_dates
    renumber_duplicate_load_numbers

    change_column_null :loads, :dropzone_id, false
    change_column_null :loads, :load_date, false
    add_index :loads, [:dropzone_id, :load_date, :load_number], unique: true, name: INDEX
  end

  def down
    remove_index :loads, name: INDEX
    remove_column :loads, :load_date
    remove_reference :loads, :dropzone, foreign_key: true
  end

  def backfill_load_dates
    select_rows("SELECT id, time_zone FROM dropzones").each do |dropzone_id, time_zone|
      zone = time_zone.presence || "Australia/Brisbane"
      zone = "Australia/Brisbane" unless select_value("SELECT 1 FROM pg_timezone_names WHERE name = #{quote(zone)}")
      execute "UPDATE loads SET load_date = (loads.created_at AT TIME ZONE 'UTC' AT TIME ZONE #{quote(zone)})::date WHERE dropzone_id = #{dropzone_id.to_i}"
    end
  end

  def renumber_duplicate_load_numbers
    days = select_rows("SELECT dropzone_id, load_date FROM loads GROUP BY dropzone_id, load_date, load_number HAVING COUNT(*) > 1 AND load_number IS NOT NULL")
    days = days.uniq
    say "Renumbering the loads of #{days.size} day(s) with duplicate numbers"

    days.each do |dropzone_id, load_date|
      rows = select_rows("SELECT id, load_number FROM loads WHERE dropzone_id = #{dropzone_id.to_i} AND load_date = #{quote(load_date)} ORDER BY created_at, id")
      taken = rows.filter_map { |_, number| number&.to_i }
      seen = []
      next_free = taken.max || 0
      rows.each do |id, number|
        number = number&.to_i
        next if number.nil?

        if seen.include?(number)
          next_free += 1
          say "load #{id} (dropzone #{dropzone_id}, #{load_date}): number #{number} -> #{next_free}", true
          execute "UPDATE loads SET load_number = #{next_free} WHERE id = #{id.to_i}"
        else
          seen << number
        end
      end
    end
  end
end
