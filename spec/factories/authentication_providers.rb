# frozen_string_literal: true

FactoryBot.define do
  factory :authentication_provider do
    uid { "MyString" }
    provider { 1 }
    user { nil }
    token { "MyString" }
  end
end
