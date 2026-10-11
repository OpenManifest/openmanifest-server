# frozen_string_literal: true

# Order numbers are unique per dropzone (BUG-050); duplicates are renumbered the way loads are (the oldest keeps the
# number). Indexes for the activity feed and the notification badge.
class AddUniqueOrderNumbersAndIndexes < ActiveRecord::Migration[8.1]
  ORDER_INDEX = "index_orders_on_dropzone_id_and_order_number"

  def up
    renumber_duplicate_order_numbers

    add_index :orders, [:dropzone_id, :order_number], unique: true, name: ORDER_INDEX
    add_index :events, [:dropzone_id, :created_at]
    add_index :notifications, [:received_by_id, :is_seen]
  end

  def down
    remove_index :notifications, [:received_by_id, :is_seen]
    remove_index :events, [:dropzone_id, :created_at]
    remove_index :orders, name: ORDER_INDEX
  end

  def renumber_duplicate_order_numbers
    dropzone_ids = select_values("SELECT DISTINCT dropzone_id FROM orders GROUP BY dropzone_id, order_number HAVING COUNT(*) > 1").map(&:to_i).uniq
    say "Renumbering the orders of #{dropzone_ids.size} dropzone(s) with duplicate numbers"

    dropzone_ids.each do |dropzone_id|
      rows = select_rows("SELECT id, order_number FROM orders WHERE dropzone_id = #{dropzone_id} ORDER BY created_at, id")
      seen = {}
      next_free = rows.map { |_, number| number.to_i }.max
      rows.each do |id, number|
        number = number.to_i
        if seen[number]
          next_free += 1
          say "order #{id} (dropzone #{dropzone_id}): number #{number} -> #{next_free}", true
          execute "UPDATE orders SET order_number = #{next_free} WHERE id = #{id.to_i}"
        else
          seen[number] = true
        end
      end
    end
  end
end
