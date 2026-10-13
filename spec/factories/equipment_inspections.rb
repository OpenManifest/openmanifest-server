# frozen_string_literal: true

FactoryBot.define do
  factory :equipment_inspection do
    equipment { nil }
    inspected_by { nil }
    membership { nil }
    form_template { association(:form_template, operator: membership.operator) }
    is_ok { true }
    definition { "" }
  end
end
