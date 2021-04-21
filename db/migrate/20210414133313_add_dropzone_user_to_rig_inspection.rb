# frozen_string_literal: true

class AddDropzoneUserToRigInspection < ActiveRecord::Migration[6.1]
  def change
    add_reference :rig_inspections, :dropzone_user, null: false, foreign_key: true
  end
end
