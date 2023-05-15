# frozen_string_literal: true

# == Schema Information
#
# Table name: dropzones
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
#  credits                    :integer
#
class Dropzone < ApplicationRecord
  include ActiveStorageSupport::SupportForBase64
  include Discard::Model
  include StateMachines::DropzoneState
  include Image::Resizer
  include MasterLogEntry::Dropzone
  include Dropzones::Configuration
  acts_as_mappable default_units: :kms,
                   default_formula: :sphere,
                   distance_field_name: :distance,
                   lat_column_name: :lat,
                   lng_column_name: :lng
  has_many :dropzone_users, -> { kept }, dependent: :destroy

  has_many :users, through: :dropzone_users
  has_many :weather_conditions, dependent: :destroy

  has_many :events, class_name: "Activity::Event"

  has_many :planes, -> { kept }, dependent: :destroy
  has_many :loads, -> { kept }, through: :planes

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

  belongs_to :location, optional: true
  belongs_to :federation
  belongs_to :rig_inspection_template,
             class_name: "FormTemplate",
             optional: true

  has_one_base64_attached :banner
  resize_attached_image :banner, size: [1280, 720]
  after_create :set_appsignal_gauge

  scope :visibility, -> (visibility) { where(state: visibility) }

  scope :with_user, -> (user, user_scope = nil) do
    dz_users = user.dropzone_users
    dz_users = dz_users.send(user_scope) if user_scope
    includes(:dropzone_users).where(
      dropzone_users: dz_users
    )
  end

  # Finding a dropzone for a user:
  # - All dropzones the user is at least Staff at
  # - All public dropzones
  # - All dropzones if the users moderation role is at least moderator
  scope :for, -> (user) {
    return kept if user.is_moderator?
    kept.with_user(user, :staff).or(
      kept.includes(:dropzone_users).visibility(:public)
    )
  }

  before_destroy do
    template = rig_inspection_template
    update(rig_inspection_template: nil)
    template.destroy unless template.nil?
  end

  def current_conditions
    weather_conditions.find_or_create_by(
      created_at: DateTime.now.beginning_of_day
    )
  end

  def timezone
    time_zone || "Australia/Brisbane"
  end

  def set_appsignal_gauge
    Appsignal.set_gauge("dropzones.count", User.count)
  end
end
