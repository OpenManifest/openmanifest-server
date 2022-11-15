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
    transient do
      federation { Federation.first }
    end
    user
    dropzone { nil }
    credits { nil }
    user_role do
      dropzone.user_roles.reload.third
    end
    license { Federation.first.licenses.sample }

    after(:create) do |dz_user, evaluator|
      create(:user_federation, federation: evaluator.federation, license: dz_user.license, user: dz_user.user)
    end
  end
end
