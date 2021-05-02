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
#  dropzone_id       :integer
#  canopy_size       :integer
#  is_public         :boolean          default(FALSE)
#
class Rig < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :dropzone, optional: true
  has_many :packs

  has_many :users, as: :packers, through: :packs

  enum rig_type: [
    :student,
    :sport,
    :tandem,
  ]

  before_save do
    rig_type = :sport unless rig_type.present?
  end
end
