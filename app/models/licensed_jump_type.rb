# == Schema Information
#
# Table name: licensed_jump_types
#
#  id           :integer          not null, primary key
#  license_id   :integer          not null
#  jump_type_id :integer          not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class LicensedJumpType < ApplicationRecord
  belongs_to :license
  belongs_to :jump_type
end
