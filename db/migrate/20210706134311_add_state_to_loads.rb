# frozen_string_literal: true

class AddStateToLoads < ActiveRecord::Migration[6.1]
  def change
    add_column :loads, :state, :integer, index: true
  end
end
