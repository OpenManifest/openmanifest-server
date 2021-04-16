# frozen_string_literal: true

# == Schema Information
#
# Table name: jump_types
#
#  id         :integer          not null, primary key
#  name       :string
#  slug       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class JumpType < ApplicationRecord
  has_many :licensed_jump_types
  has_many :licenses, through: :licensed_jump_types
end
