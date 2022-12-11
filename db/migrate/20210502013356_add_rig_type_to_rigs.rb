# frozen_string_literal: true

class AddRigTypeToRigs < ActiveRecord::Migration[6.1]
  def change
    add_column :rigs, :rig_type, :integer
    add_index :rigs, :rig_type
  end
end
