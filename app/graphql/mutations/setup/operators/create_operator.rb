# frozen_string_literal: true

module Mutations::Setup::Operators
  class CreateOperator < Mutations::BaseMutation
    field :operator, Types::OperatorType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true

    argument :industry, Types::IndustryEnum, required: true
    argument :attributes, Types::Input::OperatorInput, required: true

    def resolve(industry:, attributes:)
      mutate(
        ::Setup::Operators::CreateOperator,
        :operator,
        owner: context[:current_resource],
        industry: industry,
        **attributes.to_h.slice(
          :name,
          :lat,
          :lng,
          :certification_body_ids,
          :banner,
          :request_publication,
          :is_public,
          :primary_color,
          :secondary_color,
          :is_credit_system_enabled,
          :time_zone
        )
      )
    end

    def authorized?(industry: nil, attributes: nil)
      true
    end
  end
end
