FactoryBot.define do
  factory :event do
    resource { nil }
    action { 1 }
    dropzone_user { nil }
    message { "MyText" }
  end
end
