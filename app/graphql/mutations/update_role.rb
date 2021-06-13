module Mutations
  class UpdateRole < Mutations::BaseMutation
    field :role, Types::UserRoleType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :permission, String, required: true
    argument :enabled, Boolean, required: true
    argument :id, Int, required: false

    def resolve(id: nil, permission: nil, enabled: nil)
      model = UserRole.find(id)

      if enabled
        perm = Permission.find_or_initialize_by(
          name: permission,
          user_role_id: id,
        )
        perm.save!
      else
        model.permissions.where(name: permission).delete_all
      end

      model.reload

      {
        role: model,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        role: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotSaved => error
      # Failed save, return the errors to the client
      {
        role: nil,
        field_errors: nil,
        errors: error.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        role: nil,
        field_errors: nil,
        errors: [ error.message ]
      }
    end

    def authorized?(id: nil, attributes: nil, permission: nil, enabled: nil)
      role = UserRole.find(id)

      if !context[:current_resource].can?("updatePermissions", dropzone_id: role.dropzone_id)
        return false, {
          errors: [
            "You can't modify permission settings"
          ]
        }
      else
        true
      end
    end
  end
end