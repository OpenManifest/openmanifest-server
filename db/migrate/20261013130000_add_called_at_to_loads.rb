# frozen_string_literal: true

# UB.3: when the load was called ("called at 12:10"). Set by the state machine when the load starts boarding, cleared when the
# call is cancelled. Loads that are boarding now get the time they last changed.
class AddCalledAtToLoads < ActiveRecord::Migration[8.1]
  def up
    add_column :loads, :called_at, :datetime
    # 1 boarding
    execute "UPDATE loads SET called_at = updated_at WHERE state = 1"
  end

  def down
    remove_column :loads, :called_at
  end
end
