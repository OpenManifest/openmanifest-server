# frozen_string_literal: true

# == Schema Information
#
# Table name: dropzone_users
#
#  id           :bigint           not null, primary key
#  user_id      :bigint           not null
#  dropzone_id  :bigint           not null
#  credits      :float
#  expires_at   :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_role_id :bigint           not null
#  jump_count   :integer          default(0), not null
#
FactoryBot.define do
  factory :dropzone_user do
    user
    dropzone { nil }
    credits { nil }
    user_role {
      dropzone.user_roles.third
    }
  end

  factory :dropzone_user_with_license, parent: :dropzone_user do
    transient do
      federation { Federation.first }
      license { Federation.first.licenses.sample }
    end

    after(:create) do |dz_user, evaluator|
      create(:user_federation, federation: evaluator.federation, license: evaluator.license, user: dz_user.user)
    end
  end
end
