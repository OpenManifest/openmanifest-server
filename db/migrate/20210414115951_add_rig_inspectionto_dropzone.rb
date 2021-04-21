# frozen_string_literal: true

class AddRigInspectiontoDropzone < ActiveRecord::Migration[6.1]
  def change
    add_reference :dropzones, :checklist, null: true, foreign_key: { to_table: :checklists }
  end
end
