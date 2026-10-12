# frozen_string_literal: true

module Mutations::Manifest
  class CreateLoad < Mutations::BaseMutation
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true
    field :load, Types::Manifest::Load, null: true

    argument :attributes, Types::Input::LoadInput, required: true

    def resolve(attributes:)
      operator = (attributes[:vehicle] || attributes[:vehicles]&.first&.dig(:vehicle))&.operator
      return { load: nil, field_errors: nil, errors: ["A load needs a vehicle"] } unless operator

      Time.use_zone(operator.time_zone) do
        mutate(
          ::Manifest::CreateLoad,
          :load,
          access_context: access_context_for(operator),
          **attributes.to_h.slice(
            :name,
            :vehicle,
            :vehicles,
            :pilot,
            :gca,
            :load_master,
            :state,
            :max_slots,
            :crew,
            :destination_ids
          )
        )
      end
    end
  end

  def authorized?(attributes: nil)
    current_user = (attributes[:vehicle] || attributes[:vehicles]&.first&.dig(:vehicle)).operator.memberships.find_by(user: context[:current_resource])
    current_user.can?(:createLoad)
  end
end
