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
  has_many :equipment, -> { kept }, dependent: :destroy
  # The kinds of equipment the operator keeps track of (seeded from the industry template); declared before the form
  # templates, which the kinds use for their inspections
  has_many :equipment_kinds, -> { kept.ordered }, dependent: :destroy

  has_many :extras, -> { kept }, dependent: :destroy
  has_many :daily_logs, dependent: :destroy
  has_many :form_templates, dependent: :destroy

  has_many :sales, dependent: :destroy, as: :seller, class_name: "Order"
  has_many :purchases, dependent: :destroy, as: :buyer, class_name: "Order"

  has_many :operator_certification_bodies, dependent: :destroy
  has_many :certification_bodies, through: :operator_certification_bodies

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

  # Does a ticket type or an activity of the operator take only some ages? Then members need a date of birth.
  def age_limited?
    return @age_limited unless @age_limited.nil?

    keys = %w(min_age max_age)
    @age_limited = [ticket_types.kept, ActivityType.all].any? { |scope| keys.any? { |key| scope.exists?(["jsonb_exists(participant_limits, ?)", key]) } }
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

  # One term in the operator's words: term(:load) is "Load" (skydiving) or "Trip" (an override), term(:load, count: 2)
  # "Loads", term("crew.gca") "GCA". A key the terminology lacks is humanised. An override may be a plain string.
  def term(key, count: 1, locale: :en)
    path = key.to_s.split(".")
    forms = terminology(locale).dig(*path)
    return path.last.humanize if forms.blank?
    return forms.to_s unless forms.is_a?(Hash)

    (count == 1 ? forms["one"] : forms["other"]) || forms["one"] || forms["other"] || path.last.humanize
  end

  # Server-generated copy (notifications, push messages, activity events) in the operator's words: the Rails I18n key
  # with every term available for interpolation, e.g. "%{load} #%{number}" is "Load #3" or "Trip #3". Each term comes as
  # %{load} ("Load"), %{load_plural} ("Loads"), %{load_lower} ("load", for mid-sentence; acronyms such as "GCA" keep
  # their case) and %{load_plural_lower}; nested terms join with an underscore (%{crew_gca}, %{state_boarding}).
  def translate(key, locale: :en, **values)
    I18n.t(key, locale: locale, **term_values(locale), **values)
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

  def term_values(locale)
    flatten_terms(terminology(locale)).each_with_object({}) do |(name, forms), values|
      one = forms.is_a?(Hash) ? forms["one"] || forms["other"] : forms.to_s
      other = forms.is_a?(Hash) ? forms["other"] || one : one
      values[name.to_sym] = one
      values[:"#{name}_plural"] = other
      values[:"#{name}_lower"] = lower_first(one)
      values[:"#{name}_plural_lower"] = lower_first(other)
    end
  end

  # { "load" => {one, other}, "crew" => { "gca" => {one, other} } } to { "load" => {one, other}, "crew_gca" => {...} }
  def flatten_terms(terms, prefix = nil)
    terms.each_with_object({}) do |(key, value), flat|
      name = [prefix, key].compact.join("_")
      if value.is_a?(Hash) && !(value.key?("one") || value.key?("other"))
        flat.merge!(flatten_terms(value, name))
      elsif value.present?
        flat[name] = value
      end
    end
  end

  # "Load master" to "load master"; "GCA" stays "GCA"
  def lower_first(word)
    return word if word.blank? || word[1]&.match?(/[[:upper:]]/)

    word[0].downcase + word[1..]
  end

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
