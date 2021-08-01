# frozen_string_literal: true

class AddNameToRigs < ActiveRecord::Migration[6.1]
  def change
    add_column :rigs, :name, :string
  end
end
