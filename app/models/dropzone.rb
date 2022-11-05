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
  include Discard::Model
  include StateMachines::DropzoneState
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
  has_many :loads_today, -> (r) { kept.where(created_at: DateTime.now.in_time_zone(r.timezone).beginning_of_day..DateTime.now.in_time_zone(r.timezone).end_of_day) }, through: :planes, source: :loads

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
             optional: true,
             foreign_key: "rig_inspection_template_id"

  mount_base64_uploader :image, BannerUploader, file_name: ->(u) { "banner-#{u.id}-#{Time.current.to_i}.png" }

  after_create :set_appsignal_gauge

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
