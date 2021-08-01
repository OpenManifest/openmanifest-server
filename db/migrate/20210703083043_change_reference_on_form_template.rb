# frozen_string_literal: true

class ChangeReferenceOnFormTemplate < ActiveRecord::Migration[6.1]
  def change
    remove_column :form_templates, :created_by_id, :integer
    remove_column :form_templates, :updated_by_id, :integer
    add_reference :form_templates, :created_by, foreign_key: { to_table: :dropzone_users }
    add_reference :form_templates, :updated_by, foreign_key: { to_table: :dropzone_users }
  end
end
