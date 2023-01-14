# frozen_string_literal: true

module Mutations::Setup::Dropzones
  class ReloadWeatherCondition < Mutations::BaseMutation
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true
    field :weather_condition, Types::Dropzone::Weather::Condition, null: true

    argument :dropzone_id, Int, required: false
    argument :id, Int, required: false

    def resolve(dropzone_id: nil, id: nil)
      dz = Dropzone.find(dropzone_id)
      model = dz.weather_conditions.find(id)

      if dz.lat && dz.lng
        model.from_coordinates(dz.lat, dz.lng)
        model.guesstimate_jumprun
        model.save!
      end

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

    def authorized?(id:, dropzone_id: nil)
      if !context[:current_resource].can? :updateWeatherConditions, dropzone_id: dropzone_id
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
