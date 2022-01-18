# frozen_string_literal: true

class AddLicenseIdToDropzoneUser < ActiveRecord::Migration[6.1]
  def change
    add_reference :dropzone_users, :license, null: true, foreign_key: true
  end
end
