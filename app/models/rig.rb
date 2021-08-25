# frozen_string_literal: true

# == Schema Information
#
# Table name: rigs
#
#  id                :bigint           not null, primary key
#  make              :string
#  model             :string
#  serial            :string
#  pack_value        :integer
#  repack_expires_at :datetime
#  maintained_at     :datetime
#  user_id           :bigint
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  dropzone_id       :bigint
#  canopy_size       :integer
#  is_public         :boolean          default(FALSE)
#  rig_type          :integer
#  name              :string
#  packing_card      :text
#
class Rig < ApplicationRecord
  include CloudinaryHelper
  mount_base64_uploader :packing_card, PackingCardUploader,
  file_name: -> (u) { "packing-card-#{u.id}-#{Time.current.to_i}.png" }

  belongs_to :user, optional: true
  belongs_to :dropzone, optional: true

  has_many :packs
  has_many :users, as: :packers, through: :packs
  has_many :rig_inspections

  enum rig_type: [
    :student,
    :sport,
    :tandem,
  ]

  before_save do
    assign_attributes(rig_type: :sport) unless rig_type.present?
  end
end
