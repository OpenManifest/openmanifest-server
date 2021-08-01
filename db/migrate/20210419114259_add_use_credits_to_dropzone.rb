# frozen_string_literal: true

class AddUseCreditsToDropzone < ActiveRecord::Migration[6.1]
  def change
    add_column :dropzones, :is_credit_system_enabled, :boolean, default: false
  end
end
