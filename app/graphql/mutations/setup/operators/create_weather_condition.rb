# frozen_string_literal: true

module Mutations::Setup::Operators
  class CreateWeatherCondition < Mutations::BaseMutation
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true
    field :weather_condition, Types::Operator::Weather::Condition, null: true

    argument :attributes, Types::Input::WeatherConditionInput, required: true
    argument :id, Int, required: false

    def resolve(attributes:, id: nil)
      model = Operator.find(attributes[:operator_id]).weather_conditions.find(id)

      # Ensure only valid winds received
      winds = if attributes[:winds].present?
                JSON.parse(attributes[:winds] || "[]", symbolize_names: true)
              else
                []
      end

      winds = [] unless winds.is_a? Array
      winds = winds.map do |wind|
        {
          altitude_m: wind[:altitude_m] || 0,
          speed_mps: wind[:speed_mps] || 0,
          direction: wind[:direction] || 0,
          temperature_c: wind[:temperature_c],
        }
      end

      model.assign_attributes(attributes.to_h.merge(
        winds: winds.to_json
      ))

      model.save!

      {
        weather_condition: model,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        weather_condition: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotSaved => error
      # Failed save, return the errors to the client
      {
        weather_condition: nil,
        field_errors: nil,
        errors: error.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        weather_condition: nil,
        field_errors: nil,
        errors: [error.message],
      }
    end

    def authorized?(id:, attributes: nil)
      if !context[:current_resource].can? :updateWeatherConditions, operator_id: attributes[:operator_id]
        return false, {
          errors: [
            "You can't update weather conditions",
          ],
        }
      end
      true
    end
  end
end
