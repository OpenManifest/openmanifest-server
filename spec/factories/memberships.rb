# frozen_string_literal: true

# == Schema Information
#
# Table name: memberships
#
#  id           :bigint           not null, primary key
#  user_id      :bigint           not null
#  operator_id  :bigint           not null
#  expires_at   :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_role_id :bigint           not null
#  load_count   :integer          default(0), not null
#
FactoryBot.define do
  factory :membership do
    transient do
      federation { Federation.first }
    end
    user
    operator { nil }
    credits { nil }
    expires_at { 1.year.from_now }
    user_role do
      operator.user_roles.reload.order(:id).third
    end
    license { Federation.first.licenses.where.not(name: 'No license').sample }

    after(:create) do |dz_user, evaluator|
      create(:user_federation, federation: evaluator.federation, license: dz_user.license, user: dz_user.user)
    end
  end
end
