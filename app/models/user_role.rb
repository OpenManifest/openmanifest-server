# frozen_string_literal: true

# == Schema Information
#
# Table name: user_roles
#
#  id          :integer          not null, primary key
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  dropzone_id :integer          not null
#
class UserRole < ApplicationRecord
  has_many :permissions, dependent: :delete_all
  belongs_to :dropzone
  has_many :dropzone_users
end
