# frozen_string_literal: true

FactoryBot.define do
  factory :qualification do
    sequence(:name) { |n| "Qualification #{n}" }
    sequence(:slug) { |n| "qualification-#{n}" }
    certification_body { CertificationBody.first }
  end
end
