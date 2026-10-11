# frozen_string_literal: true

module Mutations::Setup::Demo
  class Generate < Mutations::BaseMutation
    field :operator, Types::OperatorType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true

    argument :attributes, Types::Input::DemoDataInput, required: true
    argument :operator, ID, required: true,
                            prepare: -> (id, ctx) { ::Operator.find_by(id: id) }

    def resolve(attributes:, operator:)
      mutate(
        ::Demo::DataGenerator,
        :operator,
        operator: attributes[:operator],
        access_context: access_context_for(attributes[:operator]),
        **attributes.to_h.slice(
          :gca_count,
          :dzso_count,
          :jumper_count,
          :pilot_count,
          :tandem_instructor_count,
          :aff_instructor_count,
          :rig_inspector_count,
          :coach_count
        )
      )
    end

    def authorized?(attributes: nil)
      true
    end
  end
end
