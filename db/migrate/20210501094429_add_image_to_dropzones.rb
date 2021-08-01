# frozen_string_literal: true

class AddImageToDropzones < ActiveRecord::Migration[6.1]
  def change
    add_column :dropzones, :image, :string
  end
end
