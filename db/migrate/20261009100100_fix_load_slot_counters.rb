# frozen_string_literal: true

# slots_count was incremented twice per slot and ready_slots_count never moved (BUG-019): recount both on loads and
# the slot count on dropzones. Every correction is printed.
class FixLoadSlotCounters < ActiveRecord::Migration[8.1]
  def up
    Slot.reset_column_information
    fixed = Slot.counter_culture_fix_counts
    fixed.each { |fix| say "#{fix[:entity]} #{fix[:id]}: #{fix[:what]} was #{fix[:wrong]}, now #{fix[:right]}", true }
    say "Corrected #{fixed.size} counter(s)"
  end

  def down
    # The counters were wrong before and stay right: nothing to restore
  end
end
