# frozen_string_literal: true

class ChangeReferenceOnSlot < ActiveRecord::Migration[6.1]
  def change
    remove_reference :loads, :gca
    remove_reference :loads, :load_master
    remove_reference :loads, :pilot
    add_reference :loads, :gca, foreign_key: { to_table: :dropzone_users }, null: true
    add_reference :loads, :load_master, foreign_key: { to_table: :dropzone_users }, null: true
    add_reference :loads, :pilot, foreign_key: { to_table: :dropzone_users }, null: true
  end
end
