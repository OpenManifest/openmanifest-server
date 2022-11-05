class AddUniquenessIndexToFederation < ActiveRecord::Migration[6.1]
  def change
    add_index :federations, :slug, unique: true
  end
end
