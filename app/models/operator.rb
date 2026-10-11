# frozen_string_literal: true

# == Schema Information
#
# Table name: operators
#
#  id                         :bigint           not null, primary key
#  name                       :string
#  federation_id              :bigint
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
  include MasterLogEntry::Operator
  include Operators::Configuration

  acts_as_mappable default_units: :kms,
                   default_formula: :sphere,
                   distance_field_name: :distance,
                   lat_column_name: :lat,
                   lng_column_name: :lng
  has_many :memberships, -> { kept }, dependent: :destroy

  has_many :users, through: :memberships
  has_many :weather_conditions, dependent: :destroy

  has_many :events, class_name: "Activity::Event"

  has_many :planes, -> { kept }, dependent: :destroy
  has_many :loads, -> { kept }

  has_many :load_masters, through: :loads
  has_many :ticket_types, -> { kept }, dependent: :destroy
  has_many :user_roles, dependent: :destroy
  has_many :rigs, -> { kept }, dependent: :destroy
  has_many :student_rigs, -> { kept.where(is_public: true).where.not(rig_type: :tandem) }, class_name: "Rig"
  has_many :tandem_rigs, -> { kept.where(rig_type: :tandem) }, class_name: "Rig"

  has_many :extras, -> { kept }, dependent: :destroy
  has_many :master_logs, dependent: :destroy
  has_many :form_templates, dependent: :destroy

  has_many :sales, dependent: :destroy, as: :seller, class_name: "Order"
  has_many :purchases, dependent: :destroy, as: :buyer, class_name: "Order"

  belongs_to :federation
  belongs_to :rig_inspection_template,
             class_name: "FormTemplate",
             optional: true

  has_one_base64_attached :banner
  resize_attached_image :banner, size: [1280, 720]
  after_create :set_appsignal_gauge

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
    Time.current.in_time_zone(timezone).to_date
  end

  # The weather of the operator's current day, created when it is first asked for
  def current_conditions
    weather_conditions.find_or_create_by!(date: today)
  rescue ActiveRecord::RecordNotUnique
    # Another request created it first
    weather_conditions.find_by!(date: today)
  end

  def timezone
    time_zone || "Australia/Brisbane"
  end

  def set_appsignal_gauge
    Appsignal.set_gauge("operators.count", Operator.count)
  end
end
