FactoryBot.define do
  factory :form_template do
    dropzone
    definition { '' }
    name { 'Rig Inspection Template' }
    initialize_with { dropzone.form_templates.first || dropzone.form_templates.find_or_initialize_by(name: 'Rig Inspection Template') }
  end
end
