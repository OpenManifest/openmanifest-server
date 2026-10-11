# frozen_string_literal: true

FactoryBot.define do
  factory :form_template do
    operator
    definition { "" }
    name { "Rig Inspection Template" }
    initialize_with do
      operator.form_templates.first || operator.form_templates.find_or_initialize_by(name: "Rig Inspection Template")
    end
  end
end
