# frozen_string_literal: true

module Types
  module Input
    class OperatorInput < Types::Base::Input
      argument :name, String, required: true
      argument :banner, String, required: false
      argument :federation, Int, required: false,
                                 prepare: -> (value, ctx) { Federation.find_by(id: value) }
      argument :request_publication, Boolean, required: false
      argument :is_public, Boolean, required: false
      argument :lat, Float, required: false
      argument :lng, Float, required: false
      argument :primary_color, String, required: false
      argument :secondary_color, String, required: false
      argument :is_credit_system_enabled, Boolean, required: false

      argument :settings, Types::Input::Operator::SettingsInput,
               required: false,
               description: 'Settings for the operator'
    end
  end
end
