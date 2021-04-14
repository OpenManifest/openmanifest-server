class AddSlotNumbersToLoads < ActiveRecord::Migration[6.1]
  def change
    add_column :loads, :slots, :integer
  end
end
