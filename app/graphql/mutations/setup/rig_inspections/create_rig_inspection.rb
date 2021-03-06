# frozen_string_literal: true

module Mutations::Setup::RigInspections
  class CreateRigInspection < Mutations::BaseMutation
    field :rig_inspection, Types::RigInspectionType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :attributes, Types::Input::RigInspectionInput, required: true
    argument :id, Int, required: false

    def resolve(attributes:, id: nil)
      mutate(
        ::Setup::Equipment::CreateRigInspection,
        :rig_inspection,
        dropzone: attributes[:dropzone],
        rig: attributes[:rig],
        definition: attributes[:definition],
        is_ok: attributes[:is_ok],
        access_context: access_context_for(attributes[:dropzone]),
      )
    end
  end
end
