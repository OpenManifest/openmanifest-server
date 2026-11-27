# frozen_string_literal: true

# Who to call for a member (a guest has one already): the passenger list of the boat templates shows it (P7.25)
class AddEmergencyContactToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :emergency_contact, :string
  end
end
