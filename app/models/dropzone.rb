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

  has_one_base64_attached :banner

  after_create :create_default_roles


  def create_default_roles
    {
      tandem_passenger: [
        :readLoad,
      ],
      student: [
        :readLoad,
        :createSlot,
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
      manifest: [
        :readLoad,
        :createSlot,
        :updateSlot,
        :deleteSlot,
        :createRig,
        :updateRig,
        :deleteRig,

        :createUserSlot,
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

        :readUser,
        :actAsLoadMaster,
        :actAsGCA,
        :actAsDZSO,
      ],
      admin: Permission.names.keys,
      owner: Permission.names.keys
    }.map do |role, permissions|
      role = UserRole.find_or_create_by(name: role, dropzone_id: id)
      permissions.each do |permission|
        role.permissions.create(
          name: permission
        )
      end
    end
  end
end
