# frozen_string_literal: true

class AddNameToLoads < ActiveRecord::Migration[6.1]
  def change
    add_column :loads, :name, :string
  end
end
