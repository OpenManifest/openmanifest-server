# frozen_string_literal: true

class AddDropzoneUserToSlots < ActiveRecord::Migration[6.1]
  def change
    remove_reference :slots, :user
    add_reference :slots, :dropzone_user, null: true, foreign_key: true
  end
end
