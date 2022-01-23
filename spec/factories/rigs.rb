FactoryBot.define do
  factory :rig do
    dropzone { nil }
    make { ['Vector', 'Mirage', 'Javelin'].sample }
    model { { vector: ['v310', 'v314'], javelin: ['jfk1', 'jrk14'], mirage: ['g4.1', 'g4.2'] }[make.downcase.to_sym].sample }
    serial { Faker::Number.between(from: 10000, to: 99999) }
    pack_value { 10 }
    is_public { false }
    repack_expires_at { DateTime.now + 1.year }
    canopy_size { [90, 99, 109, 119, 129, 139, 149, 159].sample }
    rig_type { :sport }
    user { nil }
  end
end
