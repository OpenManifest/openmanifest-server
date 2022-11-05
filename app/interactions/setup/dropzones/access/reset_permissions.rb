# frozen_string_literal: true

class Setup::Dropzones::Access::ResetPermissions < ApplicationInteraction
  record :dropzone

  steps :clear_role_permissions


  # Finds all removed permissions and deletes any links
  # to roles and users
  def clear_role_permissions
    UserRolePermission.includes(:permission).where(
      user_role: dropzone.user_roles,
    ).delete_all
  end


  private
    # Find all permission slugs defined in the yml
    #
    # @return [Array<String>]
    def yaml_permission_slugs
      @yaml_permission_slugs ||= (Permission.default_acting + Permission.default_crud).map(&:to_s)
    end
end
