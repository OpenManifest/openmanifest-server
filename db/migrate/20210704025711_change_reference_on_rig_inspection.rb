class ChangeReferenceOnRigInspection < ActiveRecord::Migration[6.1]
  def change
    remove_column :rig_inspections, :inspected_by_id, :integer
    add_reference :rig_inspections, :inspected_by, foreign_key: { to_table: :dropzone_users }
  end
end
