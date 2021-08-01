# frozen_string_literal: true

class AddPushTokenToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :push_token, :string
  end
end
