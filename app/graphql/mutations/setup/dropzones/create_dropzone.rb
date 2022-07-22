# frozen_string_literal: true

module Mutations::Setup::Dropzones
  class CreateDropzone < Mutations::BaseMutation
    field :dropzone, Types::DropzoneType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :attributes, Types::Input::DropzoneInput, required: true

    def resolve(attributes:)
      mutate(
        ::Setup::Dropzones::CreateDropzone,
        owner: context[:current_resource],
        **attributes.to_h.slice(
          :name,
          :lat,
          :lng,
          :federation,
          :request_publication,
          :is_public,
          :primary_color,
          :secondary_color,
          :is_credit_system_enabled
        )
      )
      model = Dropzone.new(attributes.to_h.except(:banner))

      model.save!

      ## Make current user owner
      dz_user = DropzoneUser.create(
        dropzone: model,
        user: context[:current_resource],
        user_role: UserRole.find_by(dropzone_id: model.id, name: "owner")
      )

      ::Activity::Event.create(
        level: :info,
        access_level: :admin,
        message: "A new Dropzone #{model.name} was created by #{context[:current_resource].name}",
        resource: model,
        action: :created,
        created_by: dz_user,
        dropzone: model,
      )

      model.rig_inspection_template = FormTemplate.create(
        name: "Rig Inspection",
        definition: RigInspection.default_form.to_json,
        created_by: dz_user,
        updated_by: dz_user,
      )
      model.save!
      model.rig_inspection_template.update(dropzone: model)

      {
        dropzone: model,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        dropzone: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotSaved => invalid
      # Failed save, return the errors to the client
      {
        dropzone: nil,
        field_errors: nil,
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        dropzone: nil,
        field_errors: nil,
        errors: [ error.message ]
      }
    end

    def authorized?(attributes: nil)
      true
    end
  end
end
