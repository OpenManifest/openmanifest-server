# frozen_string_literal: true

class AddFormTemplateToDropzone < ActiveRecord::Migration[6.1]
  def change
    add_reference :dropzones, :rig_inspection_template, null: true, foreign_key: { to_table: :form_templates }
  end
end
