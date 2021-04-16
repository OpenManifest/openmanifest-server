# frozen_string_literal: true

# == Schema Information
#
# Table name: rigs
#
#  id                :integer          not null, primary key
#  make              :string
#  model             :string
#  serial            :string
#  pack_value        :integer
#  repack_expires_at :datetime
#  maintained_at     :datetime
#  user_id           :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class Rig < ApplicationRecord
  belongs_to :user
  has_many :packs
  has_many :users, as: :packers, through: :packs
end
