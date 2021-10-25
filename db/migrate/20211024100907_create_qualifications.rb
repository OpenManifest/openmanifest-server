# frozen_string_literal: true

class CreateQualifications < ActiveRecord::Migration[6.1]
  def change
    create_table :qualifications do |t|
      t.string :name
      t.string :slug
      t.references :federation, null: false, foreign_key: true

      t.timestamps
    end
  end
end
