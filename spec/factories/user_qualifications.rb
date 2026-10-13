# frozen_string_literal: true

FactoryBot.define do
  factory :user_qualification do
    user_certification { nil }
    qualification { nil }
  end
end
