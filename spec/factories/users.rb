# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  provider               :string           default("email"), not null
#  uid                    :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  allow_password_change  :boolean          default(FALSE)
#  remember_created_at    :datetime
#  confirmation_token     :string
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string
#  last_sign_in_ip        :string
#  name                   :string
#  nickname               :string
#  image                  :string
#  phone                  :string
#  email                  :string
#  body_mass_kg            :float
#  certification_level_id             :bigint
#  tokens                 :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  push_token             :string
#  unconfirmed_email      :string
#  time_zone              :string           default("Australia/Brisbane")
#  load_count             :integer          default(0), not null
#  operator_count         :integer          default(0), not null
#  vehicle_count            :integer          default(0), not null
#
FactoryBot.define do
  factory :user do
    name { [Faker::Name.first_name, Faker::Name.last_name].join(" ") }
    nickname { nil }
    phone { Faker::PhoneNumber.cell_phone }
    email { Faker::Internet.email }
    body_mass_kg { Faker::Number.between(from: 60, to: 120) }
    provider { "email" }
    password { Faker::Internet.password(min_length: 10, max_length: 20) }
    confirmed_at { DateTime.now }
    moderation_role { :user }

    after(:create) do |user, _evaluator|
      user.confirm
    end
  end

  factory :user_with_certification_level, parent: :user do
    transient do
      certification_body { CertificationBody.first }
      certification_level { CertificationBody.first.certification_levels.sample }
    end

    after(:create) do |user, evaluator|
      create(:user_certification, certification_body: evaluator.certification_body, certification_level: evaluator.certification_level, user: user)
    end
  end
end
