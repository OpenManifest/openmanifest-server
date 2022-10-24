# frozen_string_literal: true

# == Schema Information
#
# Table name: dropzone_users
#
#  id           :bigint           not null, primary key
#  user_id      :bigint           not null
#  dropzone_id  :bigint           not null
#  credits      :float
#  expires_at   :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_role_id :bigint           not null
#  jump_count   :integer          default(0), not null
#
class DropzoneUser < ApplicationRecord
  include Discard::Model
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

  has_many :sales, dependent: :destroy, as: :seller, class_name: "Order"
  has_many :purchases, dependent: :destroy, as: :buyer, class_name: "Order"


  has_many :rig_inspections, dependent: :destroy
  has_many :approved_rigs, through: :rig_inspections, source: :rig

  # Automatically updated by UserFederation:
  belongs_to :license, optional: true
  has_many :licensed_jump_types, through: :license, source: :licensed_jump_types
  has_many :jump_types, through: :licensed_jump_types, source: :jump_type

  has_many :notifications, foreign_key: :received_by_id, dependent: :destroy
  scope :with_acting_permission, ->(permissionName) { includes(:permissions).where(permissions: { name: permissionName }) }
  scope :staff, -> { includes(:user_role).where.not(user_role: { name: %i[tandem_passenger student pilot fun_jumper] }) }

  validates :user_id, uniqueness: { scope: :dropzone_id }

  counter_culture :dropzone, column_name: :users_count
  delegate :exit_weight, :name, :email, :nickname, :rigs, to: :user

  after_initialize do
    assign_attributes(user_role: dropzone.user_roles.second) if user_role.nil? && !dropzone.nil?
  end

  after_create do
    Appsignal.set_gauge("dropzone.users.count", dropzone.dropzone_users.count, dropzone: dropzone.name)
  end

  search_scope :search do
    attributes name: "user.name"
  end

  # Get all inspected and approved rigs,
  # plus all dropzone student rigs.
  # If a load_id is provided, filter out
  # any rigs that are currently in use
  # on that load
  #
  # @param [Integer] load_id
  # @return [Array<Rig>]
  def available_rigs(load_id: nil)
    query = Rig.where(id: approved_rigs.pluck(:id) + dropzone.student_rigs.pluck(:id))
    query = query.where.not(
      id: Slot.where(
        load_id: load_id
      ).where.not(
        # We do this to allow the user to
        # see the rig on his/her own slot,
        # e.g don't filter it out if its taken
        # by the current user
        dropzone_user_id: id
      ).pluck(:rig_id)
    ) if load_id
    query.where("repack_expires_at > ?", DateTime.now).distinct
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
