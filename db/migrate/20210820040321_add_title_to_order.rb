# frozen_string_literal: true

class AddTitleToOrder < ActiveRecord::Migration[6.1]
  def change
    add_column :orders, :title, :string
  end
end
