# frozen_string_literal: true

# == Schema Information
#
# Table name: dropzone_users
#
#  id           :integer          not null, primary key
#  user_id      :integer          not null
#  dropzone_id  :integer          not null
#  credits      :float
#  expires_at   :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_role_id :integer          not null
#
class DropzoneUser < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :dropzone
  belongs_to :user_role
  has_many :role_permissions, source: :permissions, through: :user_role
  has_many :slots, dependent: :destroy
  has_many :form_templates, foreign_key: :created_by_id, dependent: :destroy

  has_many :loads_as_gca, class_name: "Load", foreign_key: :gca_id, dependent: :nullify
  has_many :loads_as_pilot, class_name: "Load", foreign_key: :pilot_id, dependent: :nullify
  has_many :loads_as_load_master, class_name: "Load", foreign_key: :load_master_id, dependent: :nullify

  has_many :user_permissions, dependent: :destroy
  has_many :permissions, through: :user_permissions

  has_many :transactions, dependent: :destroy
  has_many :rig_inspections, dependent: :destroy

  has_many :notifications, foreign_key: :received_by_id, dependent: :destroy
  scope :with_acting_permission, -> (permissionName) { includes(:permissions).where(permissions: { name: permissionName }) }

  validates :user_id, uniqueness: { scope: :dropzone_id }

  after_initialize do
    if user_role.nil?
      assign_attributes(user_role:  dropzone.user_roles.second)
    end
  end

  search_scope :search do
    attributes name: "user.name"
  end

  def can?(permission)
    all_permissions.where(
      name: permission
    ).exists?
  end

  # Grant the user a permission, specifically for this user
  # Permissions grante to a user must be manually revoked as they
  # are grante only to that user, and not to his or her role
  #
  # @param [String] permission_name
  def grant!(permission_name)
    unless can?(permission_name)
      user_permissions.create(
        permission: Permission.find_by(name: permission_name)
      )
    end
  end

  # Revoke a permission specifically grante to a user. Does not affect
  # the users role
  #
  # @param [String] permission_name
  def revoke!(permission_name)
    user_permissions.includes(:permission).where(
      permission: { name: permission_name }
    ).destroy_all
  end

  def all_permissions
    Permission.where(
      id: permissions.pluck(:id)
    ).or(
      Permission.where(id: role_permissions.pluck(:id))
    )
  end
end
