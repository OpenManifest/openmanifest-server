# frozen_string_literal: true

# == Schema Information
#
# Table name: equipment
#
#  id             :bigint           not null, primary key
#  discarded_at   :datetime
#  is_public      :boolean          default(FALSE)
#  maintained_at  :datetime
#  make           :string
#  model          :string
#  name           :string
#  ownership      :string           default("personal"), not null
#  packing_card   :text
#  properties     :jsonb            not null
#  serial         :string
#  service_due_at :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  kind_id        :bigint
#  operator_id    :bigint
#  user_id        :bigint
#
# An item an operator or a member keeps: a skydiving rig, a regulator, a life jacket. Its kind (EquipmentKind) says what
# `properties` it records and how it is inspected; `service_due_at` is when it next needs service (a reserve repack).
class Equipment < ApplicationRecord
  include Discard::Model
  include ActiveStorageSupport::SupportForBase64

  OWNERSHIPS = %w(personal operator).freeze

  has_one_base64_attached :packing_card

  belongs_to :kind, class_name: "EquipmentKind", inverse_of: :equipment
  belongs_to :user, optional: true
  belongs_to :operator, optional: true

  has_many :packs, dependent: :destroy
  has_many :users, as: :packers, through: :packs
  has_many :equipment_inspections, dependent: :destroy
  has_many :slot_equipment, dependent: :destroy
  has_many :slots, through: :slot_equipment

  enum :ownership, OWNERSHIPS.index_with(&:itself), default: "personal", prefix: true

  before_validation :assign_ownership, :check_properties
  validate :owner_present, :kind_of_owner

  # Items of operators that offer these kinds (a personal item has the kind of the operator it was made at; any operator
  # with a kind of the same key accepts it)
  scope :of_kind, ->(key) { joins(:kind).where(equipment_kinds: { key: key }) }

  # Items with an ok inspection at the operator that is still valid for the kind
  scope :inspected_at, ->(operator) { where(id: EquipmentInspection.ok.current.at_operator(operator).select(:equipment_id)) }
  # Items without a valid ok inspection at the operator, including items that were never inspected
  scope :not_inspected_at, ->(operator) { where.not(id: EquipmentInspection.ok.current.at_operator(operator).select(:equipment_id)) }

  scope :rentable, -> { where(ownership: "operator", is_public: true) }

  # Items on a load that has not completed
  scope :occupied, -> {
    where(id: SlotEquipment.joins(slot: :load).where(loads: { state: %i(open departed boarding), created_at: 1.day.ago..DateTime.current }).select(:equipment_id))
  }

  # Items whose service is due in the future; an item without a date is in service only when its kind is not serviced
  scope :in_service, -> {
    joins(:kind).where(
      "equipment.service_due_at > :now OR (equipment.service_due_at IS NULL AND equipment_kinds.service_interval_days IS NULL)", now: Time.current
    )
  }

  def in_service?(now: Time.current)
    return service_due_at.present? && service_due_at > now if kind.service_interval_days

    service_due_at.nil? || service_due_at > now
  end

  # Records a service: it is next due after the kind's interval
  def record_service(at: Time.current)
    return unless kind.service_interval_days

    update!(maintained_at: at, service_due_at: at + kind.service_interval_days.days)
  end

  def inspected_at?(operator)
    equipment_inspections.ok.current.at_operator(operator).exists?
  end

  # May the operator rent it out?
  def rentable?
    operator_id.present? && is_public && kind.rentable?(properties)
  end

  private

  def assign_ownership
    self.ownership = operator_id.present? ? "operator" : "personal"
  end

  def check_properties
    return unless kind

    self.properties, problems = kind.check_properties(properties)
    @property_problems = problems
  end

  def owner_present
    @property_problems&.each { |problem| errors.add(:properties, problem) }
    errors.add(:user, :blank) if ownership_personal? && user_id.blank?
  end

  def kind_of_owner
    return if kind.nil? || !ownership_operator? || kind.operator_id == operator_id

    errors.add(:kind, :invalid)
  end
end
