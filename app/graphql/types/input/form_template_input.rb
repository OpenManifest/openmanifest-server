# frozen_string_literal: true

module Types
  module Input
    class FormTemplateInput < Types::Base::Input
      argument :name, String, required: false
      argument :definition, String, required: false
      argument :operator_id, Int, required: false
    end
  end
end
