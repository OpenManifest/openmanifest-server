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
  acts_as_mappable default_units: :kms,
                   default_formula: :sphere,
                   distance_field_name: :distance,
                   lat_column_name: :lat,
                   lng_column_name: :lng
  has_many :dropzone_users, dependent: :destroy
  has_many :users, through: :dropzone_users
  has_many :weather_conditions, dependent: :destroy

  has_many :planes, dependent: :destroy
  has_many :loads, through: :planes
  has_many :loads_today, -> (r) { where(created_at: DateTime.now.in_time_zone(r.timezone).beginning_of_day..DateTime.now.in_time_zone(r.timezone).end_of_day) }, through: :planes, source: :loads

  has_many :load_masters, through: :loads
  has_many :ticket_types, dependent: :destroy
  has_many :user_roles, dependent: :destroy
  has_many :rigs, dependent: :destroy
  has_many :extras, dependent: :destroy
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

  after_create :create_default_roles

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

  def create_default_roles
    {
      tandem_passenger: [
        :readLoad
      ],
      student: %i[
        readLoad
        createSlot
      ],
      pilot: %i[
        readLoad
        createSlot
        actAsPilot
      ],
      fun_jumper: %i[
        readLoad
        createSlot
        updateSlot
        deleteSlot
        createRig
        updateRig
        deleteRig

        createPackjob
        updatePackjob
        deletePackjob
        readPackjob

        readUser
        actAsLoadMaster
        actAsGCA
      ],
      coach: %i[
        readLoad
        createSlot
        updateSlot
        deleteSlot
        createRig
        updateRig
        deleteRig

        createPackjob
        updatePackjob
        deletePackjob
        readPackjob

        readUser
        actAsLoadMaster
        actAsGCA
      ],
      aff_instructor: %i[
        readLoad
        createSlot
        updateSlot
        deleteSlot
        createRig
        updateRig
        deleteRig

        readDropzoneRig
        updateDropzoneRig
        createDropzoneRig
        updateDropzoneRig

        createPackjob
        updatePackjob
        deletePackjob
        readPackjob

        readUserTransactions
        updateWeatherConditions

        readUser
        actAsLoadMaster
        actAsGCA
        actAsDZSO
      ],
      tandem_instructor: %i[
        readLoad
        createSlot
        updateSlot
        deleteSlot
        createRig
        updateRig
        deleteRig
        readDropzoneRig
        updateDropzoneRig
        createDropzoneRig
        updateDropzoneRig

        readUserTransactions
        updateWeatherConditions

        createPackjob
        updatePackjob
        deletePackjob
        readPackjob

        readUser
        actAsLoadMaster
        actAsGCA
        actAsDZSO
      ],
      chief_instructor: %i[
        readLoad
        createSlot
        updateSlot
        deleteSlot
        createRig
        updateRig
        deleteRig
        readDropzoneRig
        updateDropzoneRig
        createDropzoneRig
        updateDropzoneRig

        updateWeatherConditions

        createPackjob
        updatePackjob
        deletePackjob
        readPackjob

        readUserTransactions
        grantPermission
        revokePermission

        readUser
        actAsLoadMaster
        actAsGCA
        actAsDZSO
      ],
      manifest: %i[
        readLoad
        updateLoad
        createLoad

        updateWeatherConditions

        createSlot
        updateSlot
        deleteSlot
        createRig
        updateRig
        deleteRig

        readDropzoneRig
        updateDropzoneRig
        createDropzoneRig
        updateDropzoneRig

        createUserSlot
        createUserSlotWithSelf
        deleteUserSlot
        updateUserSlot

        createPackjob
        updatePackjob
        deletePackjob
        readPackjob

        createFormTemplate
        updateFormTemplate
        deleteFormTemplate
        readFormTemplate

        createUserTransaction
        readUserTransactions

        grantPermission
        revokePermission

        readUser
        updateUser
        actAsLoadMaster
        actAsGCA
        actAsDZSO
      ],
      admin: Permission.without_acting.pluck(:name),
      owner: Permission.without_acting.pluck(:name)
    }.map do |role, permissions|
      role = UserRole.find_or_create_by(name: role, dropzone_id: id)
      permissions.each do |permission|
        next if permission.nil?

        role.grant! permission
      end
    end
  end
end
