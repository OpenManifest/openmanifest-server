# frozen_string_literal: true

FactoryBot.define do
  factory :rig_inspection do
    rig { nil }
    inspected_by { nil }
    membership { nil }
    form_template { create(:form_template, operator: membership.operator) }
    is_ok { true }
    definition { "" }
  end
end
