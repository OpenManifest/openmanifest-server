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
  include MasterLogEntry::DropzoneUser
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
  has_many :rigs, through: :user
  scope :with_acting_permission, ->(permissionName) { includes(:permissions).where(permissions: { name: permissionName }) }
  scope :staff, -> { includes(:user_role).where.not(user_role: { name: %i(tandem_passenger student pilot fun_jumper) }) }
  scope :owner, -> { includes(:user_role).where(user_role: { name: :owner }) }

  # Finds DropzoneUsers belonging to a dropzone in
  # a given federation
  scope :in_federation, -> (federation) { includes(:dropzone).where(dropzone: { federation: federation }) }
  scope :with_license, -> (record_or_id) { where(license: record_or_id) }

  # All dropzone users for the given user
  scope :for_user, -> (u) { where(user: u) }

  # Users manifested on a load
  scope :manifested_on, -> (load) { includes(:slots).where(slots: { load: load }) }

  # Gets dropzone users without a specific license,
  # e.g nil, or another license than the given one.
  # If none is given, get all DropzoneUsers without any license
  scope :without_license, -> (specific_license = nil) do
    next where(license: nil) unless specific_license
    without_license.or(
      where.not(license: specific_license)
    )
  end

  validates :user_id, uniqueness: { scope: :dropzone_id }

  counter_culture :dropzone, column_name: :users_count
  delegate :exit_weight,
           :name,
           :email,
           :nickname,
           to: :user

  after_initialize :set_defaults

  after_create :set_appsignal_gauge,
               :request_rig_inspection
  after_update :broadcast_subscription
  after_commit :broadcast_subscription

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
    if load_id
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
      )
    end
    query.where("repack_expires_at > ?", DateTime.now).distinct
  end

  def can?(permission)
    all_permissions.exists?(name: permission)
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

  # Get a dropzone user for any user, either find the existing one
  # or create one
  #
  # @param [User] user
  # @return [DropzoneUser]
  def self.for(dropzone, user)
    dropzone = Dropzone.find(dropzone) if dropzone.is_a?(Integer)
    dz_user = dropzone.dropzone_users.find_or_initialize_by(user: user)
    dz_user.save if dz_user.new_record?
    dz_user
  end

  def all_permissions
    Permission.where(
      id: permissions.pluck(:id)
    ).or(
      Permission.where(id: role_permissions.pluck(:id))
    )
  end

  private

  # Set up default role for new users when the DropzoneUser is initialized
  def set_defaults
    set_default_license
    set_default_role
  end

  # Sets the default role for a DropzoneUser when initializing,
  # which defaults to UserRole::DEFAULT for users that have
  # no license in the dropzone's federation, and no exit weight
  # or rig defined, and to UserRole::DEFAULT_LICENSED if license
  # exists or exit weight and rig are defined
  def set_default_role
    return unless dropzone
    return if user_role_id.present?

    # Role defaults to admin if the user has moderator role
    role ||= dropzone.user_roles.admin if user.is_moderator?

    # Role is fun jumper if the user has a rig and has set up exit weight
    role ||= dropzone.user_roles.default_licensed if license
    role ||= dropzone.user_roles.default_licensed if user.rigs.any? && user.exit_weight.present?

    # Default role is Student
    role ||= dropzone.user_roles.default

    assign_attributes(user_role: role)
  end

  def set_default_license
    return if license_id.present?
    return unless user
    license_from_federation, = user.licenses.for_federation(dropzone.federation_id)
    return unless license_from_federation
    # Find any existing UserFederations this user has for the same Federation
    assign_attributes(license: license_from_federation)
  end

  def set_appsignal_gauge
    Appsignal.set_gauge("dropzone.users.count", dropzone.dropzone_users.count, dropzone: dropzone.name)
  end

  def request_rig_inspection
    return unless user.rigs.any?
    return unless user.exit_weight
    return unless license_id
    return if rig_inspections.any?
    rig = rigs.not_inspected_at(dropzone).first
    return unless rig
    RequestRigInspectionJob.perform_now(rig, self)
  end

  # Push an update to graphql subscriptions over websockets
  def broadcast_subscription
    DzSchema.subscriptions.trigger(
      # Field name
      :user_updated,
      # Arguments
      { dropzone_user_id: id },
      # Object
      self,
      # This corresponds to `context[:current_organization_id]`
      # in the original subscription:
      dropzone_id: dropzone_id
    )
  end
end
