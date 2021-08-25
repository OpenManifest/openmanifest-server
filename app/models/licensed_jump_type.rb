# frozen_string_literal: true

# == Schema Information
#
# Table name: licensed_jump_types
#
#  id           :bigint           not null, primary key
#  license_id   :bigint           not null
#  jump_type_id :bigint           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class LicensedJumpType < ApplicationRecord
  belongs_to :license
  belongs_to :jump_type
end
