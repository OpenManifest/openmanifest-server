class CreateFormTemplates < ActiveRecord::Migration[6.1]
  def change
    create_table :form_templates do |t|
      t.string :name
      t.text :definition
      t.references :dropzone, null: true, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :updated_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
