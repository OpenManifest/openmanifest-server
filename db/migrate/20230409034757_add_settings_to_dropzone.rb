class AddSettingsToDropzone < ActiveRecord::Migration[7.0]
  def change
    add_column :dropzones, :settings, :jsonb, default: {}
  end
end
