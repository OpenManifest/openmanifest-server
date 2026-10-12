# frozen_string_literal: true

FactoryBot.define do
  factory :event do
    resource { nil }
    action { 1 }
    membership { nil }
    message { "MyText" }
  end
end
