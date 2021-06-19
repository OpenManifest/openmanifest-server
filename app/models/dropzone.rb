# frozen_string_literal: true

# == Schema Information
#
# Table name: dropzones
#
#  id                         :integer          not null, primary key
#  name                       :string
#  federation_id              :integer
#  lat                        :float
#  lng                        :float
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  is_public                  :boolean
#  primary_color              :string
#  secondary_color            :string
#  is_credit_system_enabled   :boolean          default(FALSE)
#  rig_inspection_template_id :integer
#  image                      :string
#
class Dropzone < ApplicationRecord
  has_many :dropzone_users, dependent: :destroy
  has_many :users, through: :dropzone_users

  has_many :planes, dependent: :destroy
  has_many :loads, through: :planes
  has_many :load_masters, through: :loads
  has_many :ticket_types, dependent: :destroy
  has_many :user_roles, dependent: :destroy
  has_many :rigs, dependent: :destroy
  has_many :extras, dependent: :destroy
  has_many :master_logs, dependent: :destroy

  belongs_to :federation
  belongs_to :rig_inspection_template,
             class_name: "FormTemplate",
             optional: true,
             foreign_key: "rig_inspection_template_id"

  mount_base64_uploader :image, BannerUploader, file_name: -> (u) { "banner-#{u.id}-#{Time.current.to_i}.png" }

  after_create :create_default_roles

  before_destroy do
    template = rig_inspection_template
    update(rig_inspection_template: nil)
    if !template.nil?
      template.destroy
    end
  end


  def create_default_roles
    {
      tandem_passenger: [
        :readLoad,
      ],
      student: [
        :readLoad,
        :createSlot,
      ],
      pilot: [
        :readLoad,
        :createSlot,
        :actAsPilot,
      ],
      fun_jumper: [
        :readLoad,
        :createSlot,
        :updateSlot,
        :deleteSlot,
        :createRig,
        :updateRig,
        :deleteRig,

        :createPackjob,
        :updatePackjob,
        :deletePackjob,
        :readPackjob,

        :readUser,
        :actAsLoadMaster,
        :actAsGCA
      ],
      coach: [
        :readLoad,
        :createSlot,
        :updateSlot,
        :deleteSlot,
        :createRig,
        :updateRig,
        :deleteRig,

        :createPackjob,
        :updatePackjob,
        :deletePackjob,
        :readPackjob,

        :readUser,
        :actAsLoadMaster,
        :actAsGCA
      ],
      aff_instructor: [
        :readLoad,
        :createSlot,
        :updateSlot,
        :deleteSlot,
        :createRig,
        :updateRig,
        :deleteRig,
        
        :readDropzoneRig,
        :updateDropzoneRig,
        :createDropzoneRig,
        :updateDropzoneRig,

        :createPackjob,
        :updatePackjob,
        :deletePackjob,
        :readPackjob,

        :readUserTransactions,

        :readUser,
        :actAsLoadMaster,
        :actAsGCA,
        :actAsDZSO,
      ],
      tandem_instructor: [
        :readLoad,
        :createSlot,
        :updateSlot,
        :deleteSlot,
        :createRig,
        :updateRig,
        :deleteRig,
        :readDropzoneRig,
        :updateDropzoneRig,
        :createDropzoneRig,
        :updateDropzoneRig,

        :readUserTransactions,

        :createPackjob,
        :updatePackjob,
        :deletePackjob,
        :readPackjob,

        :readUser,
        :actAsLoadMaster,
        :actAsGCA,
        :actAsDZSO,
      ],
      chief_instructor: [
        :readLoad,
        :createSlot,
        :updateSlot,
        :deleteSlot,
        :createRig,
        :updateRig,
        :deleteRig,
        :readDropzoneRig,
        :updateDropzoneRig,
        :createDropzoneRig,
        :updateDropzoneRig,

        :createPackjob,
        :updatePackjob,
        :deletePackjob,
        :readPackjob,

        :readUserTransactions,
        :grantPermission,
        :revokePermission,

        :readUser,
        :actAsLoadMaster,
        :actAsGCA,
        :actAsDZSO,
      ],
      manifest: [
        :readLoad,
        :updateLoad,
        :createLoad,

        :createSlot,
        :updateSlot,
        :deleteSlot,
        :createRig,
        :updateRig,
        :deleteRig,

        :readDropzoneRig,
        :updateDropzoneRig,
        :createDropzoneRig,
        :updateDropzoneRig,

        :createUserSlot,
        :createUserSlotWithSelf,
        :deleteUserSlot,
        :updateUserSlot,

        :createPackjob,
        :updatePackjob,
        :deletePackjob,
        :readPackjob,

        :createFormTemplate,
        :updateFormTemplate,
        :deleteFormTemplate,
        :readFormTemplate,

        :createUserTransaction,
        :readUserTransactions,

        :grantPermission,
        :revokePermission,

        :readUser,
        :updateUser,
        :actAsLoadMaster,
        :actAsGCA,
        :actAsDZSO,
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
