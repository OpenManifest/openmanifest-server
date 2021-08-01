# frozen_string_literal: true

class AddIsPaidToSlots < ActiveRecord::Migration[6.1]
  def change
    add_column :slots, :is_paid, :boolean
  end
end
