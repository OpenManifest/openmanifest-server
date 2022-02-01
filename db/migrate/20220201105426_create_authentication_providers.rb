# frozen_string_literal: true

class CreateAuthenticationProviders < ActiveRecord::Migration[6.1]
  def change
    create_table :authentication_providers do |t|
      t.string :uid
      t.integer :provider
      t.references :user, null: false, foreign_key: true
      t.string :token

      t.timestamps
    end
  end
end
