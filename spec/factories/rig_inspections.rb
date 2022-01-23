FactoryBot.define do
  factory :rig_inspection do
    rig { nil }
    inspected_by { nil }
    dropzone_user { nil }
    form_template { create(:form_template, dropzone: dropzone_user.dropzone) }
    is_ok { true }
    definition { '' }
  end
end
