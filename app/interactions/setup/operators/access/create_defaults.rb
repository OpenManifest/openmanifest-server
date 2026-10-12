# frozen_string_literal: true

# Creates the roles of an operator's industry preset (presets.yml `roles`) with their permissions. Safe to run again: it
# adds what is missing and leaves the rest (the operator owns its roles after creation).
class Setup::Operators::Access::CreateDefaults < ApplicationInteraction
  record :operator
  array :permissions, default: -> { Permission.all.to_a }

  steps :create_permissions,
        :create_default_roles,
        :assign_default_role_permissions,
        :assign_default_role_user_permissions,
        :assert_success!

  def create_permissions
    # Create all permissions and ignore failures on duplicates,
    # relying on postgres unique constraint
    permissions = Permission.slugs.map do |slug|
      Permission.new(name: slug)
    end

    Permission.import(
      permissions,
      synchronize: permissions,
      on_duplicate_key_ignore: true
    )
  end

  def create_default_roles
    @roles = role_presets.map do |name, preset|
      UserRole.new(
        name: name,
        operator: operator,
        is_default: preset["default"] == true,
        is_default_certified: preset["default_certified"] == true
      )
    end
    UserRole.import!(
      @roles,
      synchronize: @roles,
      on_duplicate_key_ignore: true
    )
  end

  def assign_default_role_permissions
    @role_permissions = default_role_permissions.filter_map do |attrs|
      UserRolePermission.new(attrs)
    end

    UserRolePermission.import!(
      @role_permissions,
      synchronize: @role_permissions,
      on_duplicate_key_ignore: true
    )
  end

  def assign_default_role_user_permissions
    @role_user_permissions = default_role_user_permissions.filter_map do |attrs|
      UserPermission.new(attrs)
    end

    UserPermission.import!(
      @role_user_permissions,
      synchronize: @role_permissions,
      on_duplicate_key_ignore: true
    )
  end

  def assert_success!
    missing_roles = role_presets.keys - operator.user_roles.reload.pluck(:name)
    fail "Failed to create roles #{missing_roles.join(', ')}" if missing_roles.any?

    missing = default_role_permissions.reject do |attrs|
      UserRolePermission.exists?(user_role_id: attrs[:user_role].id, permission_id: attrs[:permission].id)
    end
    return if missing.empty?

    missing.each { |attrs| warn "UserRole<#{attrs[:user_role].name}> Permission<#{attrs[:permission].name}>" }
    fail "Failed to create all role permissions"
  end

  private

  # @return [Hash{String => Hash}] the roles of the operator's industry: name => { default:, permissions: }
  def role_presets
    @role_presets ||= operator.industry_template.presets.fetch("roles", {})
  end

  # The permission names of a role preset: a list, or "all" for every permission
  def permission_names(role_name)
    preset = role_presets[role_name]
    return [] unless preset

    preset["permissions"] == "all" ? Permission.slugs.map(&:to_s) : Array(preset["permissions"]).map(&:to_s)
  end

  def default_role_permissions
    @default_role_permissions ||= operator.user_roles.reload.flat_map do |role|
      permission_names(role.name).filter_map do |permission|
        # Acting permissions should not be assigned to roles, only users,
        # as we want to grant and revoke these on a user basis
        next nil if /^actAs/.match?(permission)

        role_permission = permissions.find { |p| p.name.to_s == permission }
        next nil unless role_permission
        {
          user_role: role,
          permission: role_permission,
        }
      end
    end
  end

  def default_role_user_permissions
    @default_role_user_permissions ||= operator.user_roles.includes(:memberships).flat_map do |role|
      role.memberships.flat_map do |membership|
        permission_names(role.name).sort.reverse.filter_map do |permission|
          # Acting permissions should not be assigned to roles, only users,
          # as we want to grant and revoke these on a user basis
          next nil unless /^actAs/.match?(permission)

          role_permission = permissions.find { |p| p.name.to_s == permission }
          next nil unless role_permission
          {
            membership: membership,
            permission: role_permission,
          }
        end
      end
    end
  end
end
