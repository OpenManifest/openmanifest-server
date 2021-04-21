# frozen_string_literal: true

class CreatePermissions < ActiveRecord::Migration[6.1]
  def change
    drop_table :permissions, if_exists: true
    create_table :permissions do |t|
      t.integer :name
      t.references :user_role, null: false, foreign_key: true

      t.timestamps
    end
  end
end
