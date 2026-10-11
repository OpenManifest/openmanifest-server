class Types::Access::SessionType < Types::Base::Object
  field :current_user,          Types::Users::User,               null: true, broadcastable: false
  field :permissions,           [Types::Access::PermissionType],  null: true, broadcastable: false
  field :current_membership, Types::Users::Membership, null: true, broadcastable: false
  field :current_operator, Types::OperatorType, null: true, broadcastable: false

  def current_operator
    object
  end

  def permissions
    current_membership.permission_names
  end

  def current_user
    context[:current_resource]
  end

  def current_membership
    return @current_membership if defined?(@current_membership)
    @current_membership = object.memberships.find_by(user_id: context[:current_resource].id)
    @current_membership ||= object.memberships.find_or_create_by(
      user: context[:current_resource],
      user_role: object.user_roles.first
    )

    # If the user has a rig, has set up exit weight, and
    # has a license, the user should be set to fun jumper
    # if the user is anything less
    if @current_membership.user.rigs.present? && @current_membership.license.present? && @current_membership.user.exit_weight.present?
      if @current_membership.user_role_id == object.user_roles.first.id
        @current_membership.update(user_role: object.user_roles.find_by(name: :fun_jumper))
      end

      # If the user has no rigs inspected at this operator,
      # notify a staff member if no previous notifications
      unless RigInspection.exists?(membership: @current_membership)
        rig = @current_membership.rigs.find { |candidate| !candidate.inspected_at?(object) }
        RequestRigInspectionJob.perform_later(rig.id, dz_user.id) if rig
      end
    end

    dz_user
  end
end
