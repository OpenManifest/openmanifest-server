# frozen_string_literal: true

class Setup::Dropzones::Access::CreateDefaults < ApplicationInteraction
  record :dropzone
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
    @roles = UserRole.slugs.map do |slug|
      UserRole.new(
        name: slug,
        dropzone: dropzone
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
    missing_roles = @roles.pluck(:slug) - UserRole.config.keys.map(&:to_s)
    missing_role_permissions = @default_role_permissions.filter_map do |role_permission_hash|
      next nil if @role_permissions.any? do |role_permission|
        return false unless role_permission.user_role_id == role_permission_hash[:user_role].id
        return false unless role_permission.permission_id == role_permission_hash[:permission].id
        true
      end
      "UserRole<#{role_permission_hash[:user_role].name}> Permission<#{role_permission_hash[:permission].name}>"
    end

    fail "Failed to create roles #{missing_roles.join(', ')}" if missing_roles.any?
    if missing_role_permissions.any?
      missing_role_permissions.each do |message|
        warn message
      end
      fail "Failed to create all role permissions"
    end
  end

  private

  def default_role_permissions
    @default_role_permissions ||= dropzone.user_roles.filter_map do |role|
      UserRole.config[role.name.to_sym].values.flatten.filter_map do |permission|
        # Acting permissions should not be assigned to roles, only users,
        # as we want to grant and revoke these on a user basis
        next nil if /^actAs/.match?(permission)

        role_permission = permissions.find { |p| p.name.to_s == permission.to_s }
        next nil unless role_permission
        {
          user_role: role,
          permission: role_permission,
        }
      end
    end.flatten
  end

  def default_role_user_permissions
    @default_role_user_permissions ||= dropzone.user_roles.includes(:dropzone_users).filter_map do |role|
      role.dropzone_users.filter_map do |dropzone_user|
        UserRole.config[role.name.to_sym].values.flatten.sort.reverse.filter_map do |permission|
          # Acting permissions should not be assigned to roles, only users,
          # as we want to grant and revoke these on a user basis
          next nil unless /^actAs/.match?(permission)

          role_permission = permissions.find { |p| p.name.to_s == permission.to_s }
          next nil unless role_permission
          {
            dropzone_user: dropzone_user,
            permission: role_permission,
          }
        end
      end
    end.flatten || []
    @default_role_user_permissions ||= []
  end

  # Find all permission slugs defined in the yml
  #
  # @return [Array<String>]
  def yaml_permission_slugs
    @yaml_permission_slugs ||= (Permission.default_acting + Permission.default_crud).map(&:to_s)
  end
end
