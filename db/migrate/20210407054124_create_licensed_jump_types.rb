# frozen_string_literal: true

class CreateLicensedJumpTypes < ActiveRecord::Migration[6.1]
  def change
    create_table :licensed_jump_types do |t|
      t.references :license, null: false, foreign_key: true
      t.references :jump_type, null: false, foreign_key: true

      t.timestamps
    end
  end
end
