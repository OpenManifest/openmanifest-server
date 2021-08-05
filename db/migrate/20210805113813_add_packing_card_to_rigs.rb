# frozen_string_literal: true

class AddPackingCardToRigs < ActiveRecord::Migration[6.1]
  def change
    add_column :rigs, :packing_card, :text
  end
end
