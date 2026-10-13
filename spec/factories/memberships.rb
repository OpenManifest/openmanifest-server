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
      certification_body { CertificationBody.first }
    end
    user
    operator { nil }
    credits { nil }
    expires_at { 1.year.from_now }
    user_role do
      operator.user_roles.reload.order(:id).third
    end
    certification_level { CertificationBody.first.certification_levels.where.not(name: 'No license').sample }

    after(:create) do |dz_user, evaluator|
      create(:user_certification, certification_body: evaluator.certification_body, certification_level: dz_user.certification_level, user: dz_user.user)
    end
  end
end
