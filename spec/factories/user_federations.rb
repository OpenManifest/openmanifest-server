# frozen_string_literal: true

FactoryBot.define do
  factory :user_federation do
    user { nil }
    federation { nil }
    license { nil }
    initialize_with { UserFederation.find_or_initialize_by(user: user, federation: federation) }
  end
end
