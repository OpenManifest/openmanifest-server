# frozen_string_literal: true

# == Schema Information
#
# Table name: user_roles
#
#  id          :bigint           not null, primary key
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  dropzone_id :bigint           not null
#
class UserRole < ApplicationRecord
  include Config::Yaml::Roles
  DEFAULT = :student
  DEFAULT_LICENSED = :fun_jumper

  belongs_to :dropzone
  has_many :dropzone_users, dependent: :nullify
  has_many :user_role_permissions, dependent: :destroy
  has_many :permissions, through: :user_role_permissions

  scope :admin, -> { find_by(name: :admin) }
  scope :default, -> { find_by(name: DEFAULT) }
  scope :default_licensed, -> { find_by(name: DEFAULT_LICENSED) }

  validates_uniqueness_of :name, scope: :dropzone_id

  def grant!(permission_name)
    unless permissions.includes(:permissions).exists?(permissions: { name: permission_name })
      user_role_permissions.create(
        permission: Permission.find_or_create_by(name: permission_name)
      )
    end
  end

  def revoke!(permission_name)
    user_role_permissions.includes(:permission).where(permission: { name: permission_name }).destroy_all
  end
end
