# frozen_string_literal: true

FactoryBot.define do
  factory :form_template do
    operator
    definition { "" }
    name { "Equipment Inspection Template" }
    initialize_with do
      operator.form_templates.first || operator.form_templates.find_or_initialize_by(name: "Equipment Inspection Template")
    end
  end
end
