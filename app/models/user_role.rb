# frozen_string_literal: true

class UserRole < ApplicationRecord
  has_many :permissions, dependent: :delete_all
  belongs_to :dropzone
  has_many :dropzone_users
end
