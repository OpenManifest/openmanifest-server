# frozen_string_literal: true

FactoryBot.define do
  # A skydiving rig unless another kind is given
  factory :equipment do
    transient do
      rig_type { "sport" }
      canopy_size_ft2 { [90, 99, 109, 119, 129, 139, 149, 159].sample }
    end

    operator { nil }
    user { nil }
    kind do
      membership = user&.memberships&.first
      home = operator || membership&.operator || EquipmentKind.first&.operator || create(:operator)
      home.equipment_kinds.find_by!(key: "rig")
    end
    make { ["Vector", "Mirage", "Javelin"].sample }
    model { { vector: ["v310", "v314"], javelin: ["jfk1", "jrk14"], mirage: ["g4.1", "g4.2"] }[make.downcase.to_sym].sample }
    serial { Faker::Number.between(from: 10000, to: 99999) }
    is_public { false }
    service_due_at { DateTime.now + 1.year }
    properties { { "rig_type" => rig_type.to_s, "canopy_size_m2" => (canopy_size_ft2 * 0.09290304).round(4), "pack_value" => 10 } }
  end
end
