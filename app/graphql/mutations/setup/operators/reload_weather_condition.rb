# frozen_string_literal: true

module Mutations::Setup::Operators
  class ReloadWeatherCondition < Mutations::BaseMutation
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true
    field :weather_condition, Types::Operator::Weather::Condition, null: true

    # `operator_id` is not needed any more (the weather condition knows its operator) and is ignored
    argument :operator_id, Int, required: false, description: "Not needed, the weather condition belongs to its operator"
    argument :id, Int, required: true

    # Fetches the winds again, now: the caller waits for them (at most the 5 second timeout of the request)
    def resolve(id:, operator_id: nil)
      model = WeatherCondition.find(id)
      operator = model.operator

      if operator.lat.present? && operator.lng.present?
        model.from_coordinates(operator.lat, operator.lng)
        model.save!
      end

      {
        weather_condition: model,
        errors: nil,
        field_errors: nil,
      }
    rescue *FetchWindsJob::NETWORK_ERRORS
      { weather_condition: nil, field_errors: nil, errors: ["The winds could not be fetched, try again in a moment"] }
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

    def authorized?(id:, operator_id: nil)
      condition = WeatherCondition.find_by(id: id)
      return [false, { weather_condition: nil, field_errors: nil, errors: ["Weather condition not found"] }] unless condition

      unless context[:current_resource].can?(:updateWeatherConditions, operator_id: condition.operator_id)
        return [false, { weather_condition: nil, field_errors: nil, errors: ["You can't update weather conditions"] }]
      end
      true
    end
  end
end
