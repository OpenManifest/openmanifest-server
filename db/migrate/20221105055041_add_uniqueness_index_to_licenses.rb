# frozen_string_literal: true

class AddUniquenessIndexToLicenses < ActiveRecord::Migration[6.1]
  def change
    add_index :licenses, [:name, :federation_id], unique: true
    add_index :licensed_jump_types, [:license_id, :jump_type_id], unique: true
  end
end
