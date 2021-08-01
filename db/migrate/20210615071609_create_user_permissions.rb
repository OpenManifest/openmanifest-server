# frozen_string_literal: true

class CreateUserPermissions < ActiveRecord::Migration[6.1]
  def change
    create_table :user_permissions do |t|
      t.references :permission, null: false, foreign_key: true
      t.references :dropzone_user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
