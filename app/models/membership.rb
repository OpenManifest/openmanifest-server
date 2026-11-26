# frozen_string_literal: true

# == Schema Information
#
# Table name: memberships
#
#  id           :bigint           not null, primary key
#  user_id      :bigint           not null
#  operator_id  :bigint           not null
#  expires_at   :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_role_id :bigint           not null
#  load_count   :integer          default(0), not null
#
class Membership < ApplicationRecord
  include MoneyAttributes

  money :credits
  include Discard::Model
  include DailyLogEntry::Membership

  belongs_to :user, optional: true
  belongs_to :operator
  belongs_to :user_role
  has_many :role_permissions, source: :permissions, through: :user_role
  has_many :slots, dependent: :destroy
  has_many :form_templates, foreign_key: :created_by_id, dependent: :destroy

  has_many :load_crew_assignments, dependent: :destroy

  has_many :user_permissions, dependent: :destroy
  has_many :permissions, through: :user_permissions

  has_many :sales, dependent: :destroy, as: :seller, class_name: "Order"
  has_many :purchases, dependent: :destroy, as: :buyer, class_name: "Order"

  has_many :equipment_inspections, dependent: :destroy

  # Automatically updated by UserCertification:
  belongs_to :certification_level, optional: true
  has_many :permitted_activities, through: :certification_level, source: :permitted_activities
  has_many :activity_types, through: :permitted_activities, source: :activity_type

  has_many :notifications, foreign_key: :received_by_id, dependent: :destroy
  has_many :equipment, through: :user
  scope :with_acting_permission, ->(permissionName) { includes(:permissions).where(permissions: { name: permissionName }) }
  scope :staff, -> { includes(:user_role).where.not(user_role: { name: %i(tandem_guest student pilot fun_jumper) }) }
  scope :owner, -> { includes(:user_role).where(user_role: { name: :owner }) }

  # Finds Memberships belonging to an operator that accepts
  # a given certification body
  scope :in_certification_body, -> (certification_body) do
    where(operator_id: OperatorCertificationBody.where(certification_body: certification_body).select(:operator_id))
  end
  scope :with_certification_level, -> (record_or_id) { where(certification_level: record_or_id) }

  # All operator users for the given user
  scope :for_user, -> (u) { where(user: u) }

  # Users manifested on a load
  scope :manifested_on, -> (load) { includes(:slots).where(slots: { load: load }) }

  # Gets memberships without a specific certification level,
  # e.g nil, or another level than the given one.
  # If none is given, get all Memberships without any level
  scope :without_certification_level, -> (specific_certification_level = nil) do
    next where(certification_level: nil) unless specific_certification_level
    without_certification_level.or(
      where.not(certification_level: specific_certification_level)
    )
  end

  validates :user_id, uniqueness: { scope: :operator_id }

  counter_culture :operator, column_name: :users_count
  delegate :body_mass_kg,
           :name,
           :email,
           :nickname,
           to: :user

  after_initialize :set_defaults

  after_create :set_appsignal_gauge,
               :request_equipment_inspection
  after_update :broadcast_subscription
  after_commit :broadcast_subscription

  search_scope :search do
    attributes name: "user.name"
  end

  # The items the member can use at the operator: their own that passed an inspection at the operator (still valid for
  # the kind), plus the items the operator rents out, all in service. With a load, the items taken by somebody else on
  # it are left out; with a kind, only items of the kind with that key.
  #
  # @param [Integer] load_id
  # @param [String] kind the key of an equipment kind
  # @return [ActiveRecord::Relation<Equipment>]
  def available_equipment(load_id: nil, kind: nil)
    kinds = operator.equipment_kinds
    kinds = kinds.where(key: kind) if kind
    rentable = operator.equipment.rentable.includes(:kind).select { |item| item.kind.rentable?(item.properties) }

    query = Equipment.kept.in_service.where(equipment_kinds: { key: kinds.map(&:key) }).where(
      id: user.equipment.inspected_at(operator).select(:id)
    ).or(
      Equipment.kept.in_service.where(equipment_kinds: { key: kinds.map(&:key) }).where(id: rentable.map(&:id))
    )
    if load_id
      # The member sees the items on their own slot, so those are not filtered out
      taken = SlotEquipment.joins(:slot).where(slots: { load_id: load_id }).where.not(slots: { membership_id: id })
      query = query.where.not(id: taken.select(:equipment_id))
    end
    # The member's own items first
    query.distinct.order("equipment.is_public ASC", "equipment.id ASC")
  end

  # Slot permissions a member uses on themselves, and the staff permission that keeps them when the operator does not
  # allow self-manifesting (Operator setting allow_self_manifest)
  SELF_SERVICE_PERMISSIONS = {
    "createSlot" => "createUserSlot",
    "createUserSlotWithSelf" => "createUserSlot",
    "createDoubleSlot" => "createUserDoubleSlot",
    "updateSlot" => "updateUserSlot",
    "deleteSlot" => "deleteUserSlot",
  }.freeze

  MANIFEST_DESK_MESSAGE = "Manifesting is done by the manifest desk at this operator"

  def can?(permission)
    name = permission.to_s
    return false unless all_permissions.exists?(name: name)

    counterpart = SELF_SERVICE_PERMISSIONS[name]
    counterpart.nil? || operator.allow_self_manifest? || all_permissions.exists?(name: counterpart)
  end

  # True when the member holds the self-service permission through their role, but the operator has switched
  # self-manifesting off and the member has no staff counterpart: refusals then explain why
  def manifest_desk_only?(permission)
    counterpart = SELF_SERVICE_PERMISSIONS[permission.to_s]
    return false if counterpart.nil? || operator.allow_self_manifest?

    all_permissions.exists?(name: permission.to_s) && !all_permissions.exists?(name: counterpart)
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

  # The membership of a user at an operator, or nil. Never creates one: users join an operator explicitly
  # (Users::JoinOperator), checking a permission must not write (BUG-005).
  #
  # @param [Operator, Integer, String] operator
  # @param [User] user
  # @return [Membership, nil]
  def self.of(operator, user)
    operator_id = operator.respond_to?(:id) ? operator.id : operator
    kept.find_by(operator_id: operator_id, user_id: user.id)
  end

  # The names of every permission of the member, from their role and granted to them. Reads the `permissions` and
  # `role_permissions` associations, so a list of members preloads them instead of running queries for each one
  def permission_names
    names = (permissions.map(&:name) + role_permissions.map(&:name)).uniq
    return names if operator.allow_self_manifest?

    names.reject { |name| SELF_SERVICE_PERMISSIONS.key?(name) && names.exclude?(SELF_SERVICE_PERMISSIONS[name]) }
  end

  def all_permissions
    Permission.where(
      id: permissions.pluck(:id)
    ).or(
      Permission.where(id: role_permissions.pluck(:id))
    )
  end

  # The rank of the highest level the member holds at a body the operator accepts; 0 for none
  def certification_rank
    certification_level&.rank || 0
  end

  # Sets the level to the highest the user holds at the bodies the operator accepts
  def refresh_certification_level
    level = user.highest_certification_level(operator.certification_body_ids)
    # A membership defaults its level in memory when it is loaded (set_defaults), so compare with what is stored
    update_columns(certification_level_id: level&.id, updated_at: Time.current) unless level&.id == certification_level_id_in_database
  end

  private

  # Set up default role for new users when the Membership is initialized
  def set_defaults
    set_default_certification_level
    set_default_role
  end

  # Sets the default role for a Membership when initializing,
  # which defaults to UserRole::DEFAULT for users that have
  # no certification level at a body the operator accepts, and no body mass
  # or equipment defined, and to the certified default if a level
  # exists or body mass and equipment are defined
  def set_default_role
    return unless operator
    return if user_role_id.present?

    # Role defaults to admin if the user has moderator role
    role ||= operator.user_roles.admin if user.is_moderator?

    # Role is fun jumper if the user has equipment and has set up body mass
    role ||= operator.user_roles.default_licensed if certification_level
    role ||= operator.user_roles.default_licensed if user.equipment.any? && user.body_mass_kg.present?

    # Default role is Student
    role ||= operator.user_roles.default

    assign_attributes(user_role: role)
  end

  def set_default_certification_level
    return if certification_level_id.present?
    return unless user
    # The highest level the user holds at a body the operator accepts
    level = user.highest_certification_level(operator.certification_body_ids)
    return unless level

    assign_attributes(certification_level: level)
  end

  def set_appsignal_gauge
    Appsignal.set_gauge("operator.users.count", operator.memberships.count, operator: operator.name)
  end

  def request_equipment_inspection
    return unless user.equipment.any?
    return unless user.body_mass_kg
    return unless certification_level_id
    return if equipment_inspections.any?
    item = equipment.not_inspected_at(operator).first
    return unless item
    RequestEquipmentInspectionJob.perform_later(item.id, id)
  end

  # Push an update to graphql subscriptions over websockets
  def broadcast_subscription
    DzSchema.subscriptions.trigger(
      # Field name
      :user_updated,
      # Arguments
      { membership_id: id.to_s },
      # Object
      { membership_id: id.to_s }
    )
  end
end
