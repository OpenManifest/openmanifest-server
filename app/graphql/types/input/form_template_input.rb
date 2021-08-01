# frozen_string_literal: true

module Types
  module Input
    class FormTemplateInput < Types::BaseInputObject
      argument :name, String, required: false
      argument :definition, String, required: false
      argument :dropzone_id, Int, required: false
    end
  end
end
