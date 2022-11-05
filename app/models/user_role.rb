# frozen_string_literal: true

# == Schema Information
#
# Table name: user_roles
#
#  id          :bigint           not null, primary key
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  dropzone_id :bigint           not null
#
class UserRole < ApplicationRecord
  belongs_to :dropzone
  has_many :dropzone_users, dependent: :nullify
  has_many :user_role_permissions, dependent: :destroy
  has_many :permissions, through: :user_role_permissions

  validates_uniqueness_of :name, scope: :dropzone_id

  class << self
    # Parse YAML config for default configuration
    #
    # @return [Hash<Symbol, Array<String>>]
    def config
      @config ||= YAML.safe_load(
        File.read("config/seed/access.yml"),
        symbolize_names: true,
        aliases: true
      )[:roles]
    end

    # Get all default role slugs
    #
    # @return [Hash<Symbol, Array<String>>]
    def slugs
      config.keys
    end
  end

  def yaml_permission_slugs
    self.class.config[name.to_sym] || []
  end

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
