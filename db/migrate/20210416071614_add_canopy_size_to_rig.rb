# frozen_string_literal: true

class AddCanopySizeToRig < ActiveRecord::Migration[6.1]
  def change
    add_column :rigs, :canopy_size, :integer
  end
end
