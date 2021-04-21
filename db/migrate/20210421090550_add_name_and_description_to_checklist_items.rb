class AddNameAndDescriptionToChecklistItems < ActiveRecord::Migration[6.1]
  def change
    add_column :checklist_items, :name, :string
    add_column :checklist_items, :description, :text
  end
end
