# frozen_string_literal: true

class AddIsSeenToNotifications < ActiveRecord::Migration[6.1]
  def change
    add_column :notifications, :is_seen, :boolean, default: false
  end
end
