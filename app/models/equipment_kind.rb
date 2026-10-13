# frozen_string_literal: true

# == Schema Information
#
# Table name: equipment_kinds
#
#  id                          :bigint           not null, primary key
#  attribute_schema            :jsonb            not null
#  discarded_at                :datetime
#  inspection_valid_days       :integer
#  key                         :string           not null
#  name                        :string           not null
#  position                    :integer          default(0), not null
#  required_by                 :jsonb            not null
#  service_interval_days       :integer
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  inspection_form_template_id :bigint
#  operator_id                 :bigint           not null
#
# A kind of equipment an operator keeps track of (a skydiving rig, a wetsuit, a life jacket), seeded from the industry
# template's presets. The attribute schema says what an item of the kind records; `required_by` which slots need an
# item of the kind; the inspection form and how long an inspection stays valid belong to the kind too.
#
# attribute_schema: { "canopy_size_m2" => { "type" => "decimal", "min" => 0, "unit" => "area" }, ... }
#   label     what the screens call it (the name made readable without one)
#   type      string | integer | decimal | enum | date (a date is stored as an ISO 8601 string)
#   values    the choices of an enum
#   required  true when an item must have it
#   default   used when an item does not say
#   min, max  bounds of an integer or decimal
#   unit      the quantity (see Units) of a number the operator shows in its own unit; stored SI
#   operator_only  only equipment of the operator has it (the screens leave it out for a member's own)
#   not_rentable  values with which an item of the operator is not rented out (tandem rigs)
#
# required_by: { "always" => true } or { "ticket_type_ids" => [...], "activity_type_ids" => [...] }
class EquipmentKind < ApplicationRecord
  include Discard::Model

  ATTRIBUTE_TYPES = %w(string integer decimal enum date).freeze
  KEY_FORMAT = /\A[a-z][a-z0-9_]*\z/

  belongs_to :operator
  belongs_to :inspection_form_template, class_name: "FormTemplate", optional: true
  has_many :equipment, foreign_key: :kind_id, inverse_of: :kind, dependent: :restrict_with_error

  validates :key, presence: true, format: { with: KEY_FORMAT }, uniqueness: { scope: :operator_id, conditions: -> { kept } }
  validates :name, presence: true
  validates :service_interval_days, :inspection_valid_days, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :schema_valid

  scope :ordered, -> { order(:position, :id) }

  # Adds the kinds of the operator's industry template that it does not have (once; the operator owns them afterwards),
  # each with a copy of the inspection form its preset names
  def self.create_presets!(operator, created_by: nil)
    presets = operator.industry_template.presets
    presets.fetch("equipment_kinds", []).each_with_index do |attrs, position|
      next if operator.equipment_kinds.exists?(key: attrs.fetch("key"))

      kind = operator.equipment_kinds.new(
        attrs.slice("key", "name", "attribute_schema", "service_interval_days", "inspection_valid_days", "required_by").merge("position" => position)
      )
      definition = presets.dig("inspection_forms", attrs["inspection_form"]) if attrs["inspection_form"]
      if definition.present?
        kind.inspection_form_template = ::FormTemplate.create!(
          name: attrs["inspection_form"].humanize, definition: definition.to_json, operator: operator, created_by: created_by, updated_by: created_by
        )
      end
      kind.save!
    end
  end

  # Does a slot with this ticket type and activity type need an item of the kind?
  def required_for?(ticket_type_id: nil, activity_type_id: nil)
    return true if required_by["always"]

    Array(required_by["ticket_type_ids"]).map(&:to_i).include?(ticket_type_id.to_i) ||
      Array(required_by["activity_type_ids"]).map(&:to_i).include?(activity_type_id.to_i)
  end

  # Is an inspection of the kind, made at `inspected_at`, still valid? Without a validity it stays so until the item is replaced.
  def inspection_valid?(inspected_at, now: Time.current)
    inspection_valid_days.nil? || inspected_at > now - inspection_valid_days.days
  end

  # Checks properties against the schema.
  #
  # @return [Array(Hash, Array<String>)] the properties with defaults and numbers coerced, and the problems found
  def check_properties(properties)
    properties = (properties || {}).to_h.stringify_keys
    problems = (properties.keys - attribute_schema.keys).map { |name| "#{name} is not an attribute of #{self.name}" }
    checked = {}

    attribute_schema.each do |name, spec|
      value = properties.fetch(name, spec["default"])
      if value.nil? || value == ""
        problems << "#{name} is required" if spec["required"]
        next
      end

      coerced, problem = coerce(value, spec)
      problem ? problems << "#{name} #{problem}" : checked[name] = coerced
    end

    [checked, problems]
  end

  # Can an item with these properties be rented out?
  def rentable?(properties)
    attribute_schema.none? { |name, spec| Array(spec["not_rentable"]).include?(properties[name]) }
  end

  private

  def coerce(value, spec)
    case spec["type"]
    when "string" then [value.to_s, nil]
    when "integer" then bounded(Integer(value.to_s, 10), spec)
    when "decimal" then bounded(Float(value.to_s).round(4), spec)
    when "enum" then Array(spec["values"]).include?(value.to_s) ? [value.to_s, nil] : [nil, "must be one of #{Array(spec['values']).join(', ')}"]
    when "date" then [Date.iso8601(value.to_s).iso8601, nil]
    end
  rescue ArgumentError, TypeError
    [nil, "is not a valid #{spec['type']}"]
  end

  def bounded(number, spec)
    return [nil, "must be at least #{spec['min']}"] if spec["min"] && number < spec["min"]
    return [nil, "must be at most #{spec['max']}"] if spec["max"] && number > spec["max"]

    [number, nil]
  end

  def schema_valid
    unless attribute_schema.is_a?(Hash)
      return errors.add(:attribute_schema, "must be a hash of attributes")
    end

    attribute_schema.each do |name, spec|
      errors.add(:attribute_schema, "#{name} is not a valid attribute name") unless name.match?(KEY_FORMAT)
      type = spec.is_a?(Hash) ? spec["type"] : nil
      errors.add(:attribute_schema, "#{name} has an unknown type") unless ATTRIBUTE_TYPES.include?(type)
      errors.add(:attribute_schema, "#{name} needs the values it can have") if type == "enum" && Array(spec["values"]).empty?
      errors.add(:attribute_schema, "#{name} is in an unknown unit") if spec.is_a?(Hash) && spec["unit"] && !Units::FACTORS.key?(spec["unit"].to_s)
    end
  end
end
