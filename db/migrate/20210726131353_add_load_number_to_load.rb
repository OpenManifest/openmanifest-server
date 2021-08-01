# frozen_string_literal: true

class AddLoadNumberToLoad < ActiveRecord::Migration[6.1]
  def change
    add_column :loads, :load_number, :integer
  end
end
