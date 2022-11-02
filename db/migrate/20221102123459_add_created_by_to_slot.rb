# frozen_string_literal: true

class AddCreatedByToSlot < ActiveRecord::Migration[6.1]
  def change
    add_reference :slots, :created_by, null: true, foreign_key: { to_table: :dropzone_users }
  end
end
