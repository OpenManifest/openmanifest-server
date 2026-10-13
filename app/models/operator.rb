# frozen_string_literal: true

# == Schema Information
#
# Table name: operators
#
#  id                         :bigint           not null, primary key
#  name                       :string
#  lat                        :float
#  lng                        :float
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  is_public                  :boolean
#  primary_color              :string
#  secondary_color            :string
#  is_credit_system_enabled   :boolean          default(FALSE)
#  rig_inspection_template_id :bigint
#  image                      :string
#  time_zone                  :string           default("Australia/Brisbane")
#  users_count                :integer          default(0), not null
#  slots_count                :integer          default(0), not null
#  loads_count                :integer          default(0), not null
#
class Operator < ApplicationRecord
  include MoneyAttributes

  money :credits
  include ActiveStorageSupport::SupportForBase64
  include Discard::Model
  include StateMachines::OperatorState
  include Image::Resizer
  include DailyLogEntry::Operator
  include Operators::Configuration

  acts_as_mappable default_units: :kms,
                   default_formula: :sphere,
                   distance_field_name: :distance,
                   lat_column_name: :lat,
                   lng_column_name: :lng
  # The longest call schedule an operator can set (whole minutes before departure, longest first)
  CALL_SCHEDULE_MAX = 6

  has_many :memberships, -> { kept }, dependent: :destroy
  has_many :operator_activity_types, dependent: :destroy
  has_many :activity_types, through: :operator_activity_types

  has_many :users, through: :memberships
  has_many :weather_conditions, dependent: :destroy

  has_many :events, class_name: "Activity::Event"

  has_many :vehicles, -> { kept }, dependent: :destroy
  has_many :loads, -> { kept }, dependent: :destroy
  has_many :destinations, -> { kept }, dependent: :destroy
  has_many :crew_roles, dependent: :destroy

  has_many :load_masters, through: :loads
  has_many :ticket_types, -> { kept }, dependent: :destroy
  has_many :user_roles, dependent: :destroy
  has_many :rigs, -> { kept }, dependent: :destroy
  has_many :student_rigs, -> { kept.where(is_public: true).where.not(rig_type: :tandem) }, class_name: "Rig"
  has_many :tandem_rigs, -> { kept.where(rig_type: :tandem) }, class_name: "Rig"

  has_many :extras, -> { kept }, dependent: :destroy
  has_many :daily_logs, dependent: :destroy
  has_many :form_templates, dependent: :destroy

  has_many :sales, dependent: :destroy, as: :seller, class_name: "Order"
  has_many :purchases, dependent: :destroy, as: :buyer, class_name: "Order"

  has_many :operator_certification_bodies, dependent: :destroy
  has_many :certification_bodies, through: :operator_certification_bodies
  belongs_to :rig_inspection_template,
             class_name: "FormTemplate",
             optional: true

  has_one_base64_attached :banner
  resize_attached_image :banner, size: [1280, 720]
  after_create :set_appsignal_gauge

  validates :industry, presence: true, inclusion: { in: ->(_) { Industry.slugs }, message: :unknown_industry }, on: :create
  validates :time_zone, presence: true
  validates :currency, format: { with: /\A[A-Z]{3}\z/ }
  # Only industries with certifications accept certification bodies, and then at least one
  validates :certification_bodies, presence: true, if: -> { module?(:certifications) }
  validate :industry_unchanged, on: :update
  validate :module_overrides_allowed, :call_schedule_valid, :units_known

  scope :visibility, -> (visibility) { where(state: visibility) }

  scope :with_user, -> (user, user_scope = nil) do
    dz_users = user.memberships
    dz_users = dz_users.send(user_scope) if user_scope
    includes(:memberships).where(
      memberships: dz_users
    )
  end

  # Finding an operator for a user:
  # - All operators the user is at least Staff at
  # - All public operators
  # - All operators if the users moderation role is at least moderator
  scope :for, -> (user) {
    return kept if user.is_moderator?
    kept.with_user(user, :staff).or(
      kept.includes(:memberships).visibility(:public)
    )
  }

  before_destroy do
    template = rig_inspection_template
    update(rig_inspection_template: nil)
    template.destroy unless template.nil?
  end

  # Today's date where the operator is (the server runs in UTC, the operator is not)
  def today
    Time.current.in_time_zone(time_zone).to_date
  end

  # The weather of the operator's current day, created when it is first asked for
  def current_conditions
    weather_conditions.find_or_create_by!(date: today)
  rescue ActiveRecord::RecordNotUnique
    # Another request created it first
    weather_conditions.find_by!(date: today)
  end

  def set_appsignal_gauge
    Appsignal.set_gauge("operators.count", Operator.count)
  end

  # @return [Industry] the template this operator was created from
  def industry_template = Industry.fetch(industry)

  # Is a module on? The template says, the operator's own `modules` override it (true / false / a configuration)
  def module?(name)
    override = modules[name.to_s]
    return override != false && override.present? unless override.nil?

    industry_template.module?(name)
  end

  # The configuration of a module that is on, or nil
  def module_config(name)
    return nil unless module?(name)

    override = modules[name.to_s]
    override.is_a?(Hash) ? override : industry_template.modules[name.to_s]
  end

  # Terms in a language: the template's, deep-merged with the operator's own in settings["terminology"]
  def terminology(locale = :en)
    industry_template.terminology(locale).deep_merge(settings.fetch("terminology", {}))
  end

  # Units: the template's, then settings["units"]
  def units
    industry_template.units.merge(settings.fetch("units", {}))
  end

  # Minutes before departure at which a boarding call is offered: settings["call_schedule_minutes"] or the template's
  # An empty list is the operator's choice (no calls, loads depart directly); only a schedule never set is the template's
  def call_schedule_minutes
    settings["call_schedule_minutes"].nil? ? industry_template.call_schedule_minutes : settings["call_schedule_minutes"]
  end

  # Where destinations apply, from the destinations module: "per_slot" (every slot has its own), "per_load" (a load
  # visits an ordered list) or nil when the operator has no destinations
  def destination_scope = module_config(:destinations)&.fetch("scope", nil)

  def destinations_per_slot? = destination_scope == "per_slot"

  def destinations_per_load? = destination_scope == "per_load"

  # The kinds of vehicle the operator runs (copied from the template at creation)
  def vehicle_kinds
    settings["vehicle_kinds"].presence || industry_template.vehicle_kinds
  end

  private

  # settings["units"] names a unit the quantity can be shown in: { "altitude" => "m", "mass" => "lb", ... }
  def units_known
    chosen = settings["units"]
    return if chosen.nil?

    unknown = chosen.is_a?(Hash) ? chosen.reject { |quantity, unit| Units.valid?(quantity, unit) } : { "units" => chosen }
    errors.add(:base, "Unknown units: #{unknown.map { |quantity, unit| "#{quantity} in #{unit}" }.join(', ')}") if unknown.any?
  end

  def call_schedule_valid
    schedule = settings["call_schedule_minutes"]
    return if schedule.nil?

    valid = schedule.is_a?(Array) && schedule.size <= CALL_SCHEDULE_MAX && schedule.all?(Integer) &&
            schedule.all?(&:positive?) && schedule == schedule.uniq.sort.reverse
    errors.add(:base, "The call schedule is up to #{CALL_SCHEDULE_MAX} whole minutes, longest first") unless valid
  end

  # Overrides name known modules, and a module the template marks `locked` stays on
  def module_overrides_allowed
    modules.each do |name, value|
      if Industry::MODULES.exclude?(name)
        errors.add(:modules, "#{name} is not a module")
      elsif value == false && industry_template.modules.dig(name, "locked") == true
        errors.add(:modules, "#{name} cannot be turned off")
      end
    end
  end

  # The industry is chosen at creation and never changes (GENERALISATION §2)
  def industry_unchanged
    errors.add(:industry, "cannot be changed") if industry_changed?
  end
end
