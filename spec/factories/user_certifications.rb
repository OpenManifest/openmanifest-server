# frozen_string_literal: true

FactoryBot.define do
  factory :user_certification do
    user { nil }
    certification_body { nil }
    certification_level { nil }
    initialize_with { UserCertification.find_or_initialize_by(user: user, certification_body: certification_body) }
  end
end
