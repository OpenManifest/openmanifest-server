# frozen_string_literal: true

class AddIsOpenToLoads < ActiveRecord::Migration[6.1]
  def change
    add_column :loads, :is_open, :boolean
  end
end
