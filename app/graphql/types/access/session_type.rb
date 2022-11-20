class Types::Access::SessionType < Types::BaseObject
  field :current_user, Types::UserType, null: true
  field :permissions, [Types::Access::PermissionType], null: true
  field :current_dropzone_user, Types::DropzoneUserType, null: true
  field :current_dropzone, Types::DropzoneType, null: true

  def current_dropzone
    object
  end

  def permissions
    current_dropzone_user.all_permissions.pluck(:name)
  end

  def current_user
    context[:current_resource]
  end

  def current_dropzone_user
    return @current_dropzone_user if defined?(@current_dropzone_user)
    unless @current_dropzone_user = object.dropzone_users.find_by(user_id: context[:current_resource].id)
      @current_dropzone_user = object.dropzone_users.find_or_create_by(
        user: context[:current_resource],
        user_role: object.user_roles.first
      )
    end

    # If the user has a rig, has set up exit weight, and
    # has a license, the user should be set to fun jumper
    # if the user is anything less
    if @current_dropzone_user.user.rigs.present? && @current_dropzone_user.license.present? && @current_dropzone_user.user.exit_weight.present?
      if @current_dropzone_user.user_role_id == object.user_roles.first.id
        @current_dropzone_user.update(user_role: object.user_roles.find_by(name: :fun_jumper))
      end

      # If the user has no rigs inspected at this dropzone,
      # notify a staff member if no previous notifications
      unless RigInspection.exists?(dropzone_user: @current_dropzone_user)
        RequestRigInspectionJob.perform_now(@current_dropzone_user.rigs.find { |rig| !rig.inspected_at?(object) }, dz_user)
      end
    end

    dz_user
  end
end