class CreateUserFederationQualifications < ActiveRecord::Migration[6.1]
  def change
    create_table :user_federation_qualifications do |t|
      t.references :user_federation, null: false, foreign_key: true
      t.references :qualification, null: false, foreign_key: true
      t.datetime :expires_at, null: true
      t.string :uid, null: true
      t.timestamps
    end
  end
end
