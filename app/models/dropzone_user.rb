# frozen_string_literal: true

# == Schema Information
#
# Table name: dropzone_users
#
#  id           :bigint           not null, primary key
#  user_id      :bigint           not null
#  dropzone_id  :bigint           not null
#  credits      :float
#  expires_at   :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_role_id :bigint           not null
#  jump_count   :integer          default(0), not null
#
class DropzoneUser < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :dropzone
  belongs_to :user_role
  has_many :role_permissions, source: :permissions, through: :user_role
  has_many :slots, dependent: :destroy
  has_many :form_templates, foreign_key: :created_by_id, dependent: :destroy

  has_many :loads_as_gca, class_name: "Load", foreign_key: :gca_id, dependent: :nullify
  has_many :loads_as_pilot, class_name: "Load", foreign_key: :pilot_id, dependent: :nullify
  has_many :loads_as_load_master, class_name: "Load", foreign_key: :load_master_id, dependent: :nullify

  has_many :user_permissions, dependent: :destroy
  has_many :permissions, through: :user_permissions

  has_many :sales, dependent: :destroy, as: :seller, class_name: "Order"
  has_many :purchases, dependent: :destroy, as: :buyer, class_name: "Order"

  has_many :rig_inspections, dependent: :destroy

  has_many :notifications, foreign_key: :received_by_id, dependent: :destroy
  scope :with_acting_permission, ->(permissionName) { includes(:permissions).where(permissions: { name: permissionName }) }

  validates :user_id, uniqueness: { scope: :dropzone_id }

  counter_culture :dropzone, column_name: :users_count
  delegate :exit_weight, :name, :email, :nickname, :rigs, to: :user
  before_save :sync_federation

  after_initialize do
    assign_attributes(user_role: dropzone.user_roles.second) if user_role.nil? && !dropzone.nil?
  end

  search_scope :search do
    attributes name: "user.name"
  end

  def can?(permission)
    all_permissions.where(
      name: permission
    ).exists?
  end

  # Grant the user a permission, specifically for this user
  # Permissions grante to a user must be manually revoked as they
  # are grante only to that user, and not to his or her role
  #
  # @param [String] permission_name
  def grant!(permission_name)
    unless can?(permission_name)
      user_permissions.create(
        permission: Permission.find_by(name: permission_name)
      )
    end
  end

  # Revoke a permission specifically grante to a user. Does not affect
  # the users role
  #
  # @param [String] permission_name
  def revoke!(permission_name)
    user_permissions.includes(:permission).where(
      permission: { name: permission_name }
    ).destroy_all
  end

  def all_permissions
    Permission.where(
      id: permissions.pluck(:id)
    ).or(
      Permission.where(id: role_permissions.pluck(:id))
    )
  end

  def sync_federation
    return unless dropzone && dropzone.federation
    if dropzone.federation.slug == 'apf'
      sync_apf
    end
  end

  def sync_apf
    return unless user
    return unless user.apf_number
    *_, last_name = user.name.split(/\s+/)
    return unless last_name
    
    url = "https://www.apf.com.au/apf/api/student"
    params = {
      SurName: last_name,
      APFNum: user.apf_number
    }

    response = JSON.parse(
      URI.open(
        [url, params.to_query].join('?')
      ).read
    )

    if response.count == 1
      user_info, = response

      # Find license that have not expired
      valid_licenses = user_info['Qualifications'].filter_map do |license_or_crest|
        License.find_by(name: license_or_crest['Qualification']) if License.exists?(name: license_or_crest['Qualification'])
      end

      # Find the highest ranking license
      if license = License.find_by(id: valid_licenses.map(&:id).last)
        user.update(license: license)
      end
    end
  rescue => e
    puts e.message
    nil
  end
end
