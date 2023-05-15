# frozen_string_literal: true

module Types
  module Input
    class DropzoneInput < Types::Base::Input
      argument :name, String, required: true
      argument :banner, String, required: false
      argument :federation, Int, required: false,
                                 prepare: -> (value, ctx) { Federation.find_by(id: value) }
      argument :request_publication, Boolean, required: false
      argument :is_public, Boolean, required: false
      argument :location, ID, required: false,
                              prepare: -> (value, ctx) { ::Location.find_by(id: value) }
      argument :primary_color, String, required: false
      argument :secondary_color, String, required: false
      argument :is_credit_system_enabled, Boolean, required: false

      argument :settings, Types::Input::Dropzone::SettingsInput,
               required: false,
               description: 'Settings for the dropzone'
    end
  end
end
