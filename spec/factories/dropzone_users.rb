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
end
