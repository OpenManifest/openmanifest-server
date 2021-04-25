class AddRigInspectionToChecklistValues < ActiveRecord::Migration[6.1]
  def change
    add_reference :checklist_values, :rig_inspection, null: false, foreign_key: { to_table: :rig_inspections }
  end
end
