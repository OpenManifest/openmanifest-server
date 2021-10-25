# frozen_string_literal: true

class CreateUserFederations < ActiveRecord::Migration[6.1]
  def change
    create_table :user_federations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :federation, null: false, foreign_key: true
      t.references :license, null: true, foreign_key: true
      t.string :uid, null: true
      t.string :license_number, null: true

      t.timestamps
    end
  end
end
