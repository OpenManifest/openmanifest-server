class AddRigTypeToRigs < ActiveRecord::Migration[6.1]
  def change
    add_column :rigs, :rig_type, :integer, index: true
  end
end
