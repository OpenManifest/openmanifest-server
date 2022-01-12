# frozen_string_literal: true

module Mutations
  class UpdateUser < Mutations::BaseMutation
    field :user, Types::UserType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :attributes, Types::Input::UserInput, required: true
    argument :id, Int, required: false

    def resolve(attributes: nil, id: nil)
      model = User.find(id)
      model.assign_attributes(attributes.to_h)

      model.save!

      # If license id changed, then update all DropzoneUsers
      # with the same federation as that license to have the
      # new license:
      if attributes[:license_id] && new_license = License.find(attributes[:license_id])
        Federations::AssignUser.run(
          user: model,
          license_id: new_license.id,
          federation: new_license.federation,
        )

        # Also update all dropzone_users
      end
      {
        user: model.reload,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        user: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotSaved => invalid
      # Failed save, return the errors to the client
      {
        user: nil,
        field_errors: nil,
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        user: nil,
        field_errors: nil,
        errors: [ error.message ]
      }
    end

    def authorized?(id: nil, attributes: nil)
      if context[:current_resource].id == id
        true
      else
        return false, {
        errors: [
          "You cant update other users"
          ]
        }
      end
    end

    def find_or_build_model(id)
      if id
        User.find(id)
      else
        User.new
      end
    end
  end
end
