# frozen_string_literal: true

# == Schema Information
#
# Table name: user_roles
#
#  id          :bigint           not null, primary key
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  operator_id :bigint           not null
#  is_default  :boolean          default(FALSE), not null
#  is_default_certified :boolean default(FALSE), not null
#
class UserRole < ApplicationRecord
  belongs_to :operator
  has_many :memberships, dependent: :nullify
  has_many :user_role_permissions, dependent: :destroy
  has_many :permissions, through: :user_role_permissions

  scope :admin, -> { find_by(name: :admin) }
  # The role a new member gets, and the one a member with a licence (a certification) gets; set by the industry preset
  scope :default, -> { find_by(is_default: true) }
  scope :default_licensed, -> { find_by(is_default_certified: true) }
  scope :below, -> (other_role) { where("user_roles.id < ?", other_role.id) }
  scope :above, -> (other_role) { where("user_roles.id > ?", other_role.id) }

  validates_uniqueness_of :name, scope: :operator_id

  def grant!(permission_name)
    unless permissions.includes(:permissions).exists?(permissions: { name: permission_name })
      user_role_permissions.create(
        permission: Permission.find_or_create_by(name: permission_name)
      )
    end
  end

  def revoke!(permission_name)
    user_role_permissions.includes(:permission).where(permission: { name: permission_name }).destroy_all
  end
end
