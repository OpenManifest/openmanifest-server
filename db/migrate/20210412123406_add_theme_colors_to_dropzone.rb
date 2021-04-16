# frozen_string_literal: true

class AddThemeColorsToDropzone < ActiveRecord::Migration[6.1]
  def change
    add_column :dropzones, :primary_color, :string
    add_column :dropzones, :secondary_color, :string
  end
end
