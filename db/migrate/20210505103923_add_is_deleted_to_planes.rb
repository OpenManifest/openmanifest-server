# frozen_string_literal: true

class AddIsDeletedToPlanes < ActiveRecord::Migration[6.1]
  def change
    add_column :planes, :is_deleted, :boolean, default: false
  end
end
