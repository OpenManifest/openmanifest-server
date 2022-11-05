# frozen_string_literal: true

class Setup::Global::Seeds::Permissions < ApplicationInteraction
  steps :clear_removed_permissions,
        :import_new_permissions

  # Finds all removed permissions and deletes any links
  # to roles and users
  def clear_removed_permissions
    return unless removed_permissions.any?
    UserRolePermission.includes(:permission).where(
      permission: removed_permissions
    ).delete_all

    UserPermission.includes(:permission).where(
      permission: removed_permissions
    ).delete_all
    removed_permissions.destroy_all
  end

  # Finds any permissions that are missing and creates them,
  # and assigns them to their default roles
  def import_new_permissions
    return unless new_permissions.any?

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

    ::Dropzone.all.each do |dropzone|
      compose(
        ::Setup::Dropzones::Access::CreateDefaults,
        permissions: permissions.to_a,
        dropzone: dropzone
      )
    end
  end

  private
    # Find all permission slugs defined in the yml
    #
    # @return [Array<String>]
    def yaml_permission_slugs
      @yaml_permission_slugs ||= (Permission.default_acting + Permission.default_crud).map(&:to_s)
    end

    # Find all permissions that are no longer defined in the yml file
    #
    # @return [Array<String>]
    def removed_permissions
      @removed_permissions ||= Permission.where(name: Permission.pluck(:name) - yaml_permission_slugs)
    end

    # Find all permission slugs defined in the yml file that don't exist
    #
    # @return [Array<String>]
    def new_permission_slugs
      @new_permission_slugs ||= yaml_permission_slugs - Permission.pluck(:name)
    end

    # Initialize Permissions from the new permission slugs
    #
    # @return [Array<Permission>]
    def new_permissions
      @new_permissions ||= new_permission_slugs.map do |slug|
        Permission.new(name: slug)
      end
    end
end
