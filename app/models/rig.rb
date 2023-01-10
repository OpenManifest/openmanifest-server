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
  include Discard::Model
  include ActiveStorageSupport::SupportForBase64
  has_one_base64_attached :packing_card

  belongs_to :user, optional: true
  belongs_to :dropzone, optional: true

  has_many :packs
  has_many :users, as: :packers, through: :packs
  has_many :rig_inspections
  has_many :slots, dependent: :nullify

  enum rig_type: { :student => 0, :sport => 1, :tandem => 2 }

  scope :with_inspection_at, -> (dz) { includes(rig_inspections: :inspected_by).where(rig_inspections: { dropzone_users: { dropzone_id: dz } }) }
  scope :inspected_at, -> (dz) { with_inspection_at(dz).where(rig_inspections: { is_ok: true }) }
  scope :not_inspected_at, -> (dz) { with_inspection_at(dz).where.not(rig_inspections: { is_ok: true }) }
  scope :student, -> { where(rig_type: :student) }
  scope :rentable, -> { where(is_public: true) }

  # Find all rigs that are currently manifested on a load
  # that has not yet been dispatched
  scope :occupied, -> {
    includes(slots: :load).where(
      slots: {
        # Filter out all rigs on a load that hasnt landed
        loads: {
          state: %i(open in_flight boarding_call),
          created_at: 1.day.ago..DateTime.current,
        },
      }
    )
  }

  scope :available_for, -> (dropzone_user) {
    # All rentable student rigs that are not on a load
    # currently in flight, boarding, or manifesting
    student.rentable.where.not(id: occupied).or(
      # All rigs belonging to the user that have been inspected
      # at this dropzone
      Rig.where(id: dropzone_user.rigs.inspected_at(dropzone_user.dropzone))
    ).where(
      # Ensure all results either belong to the user or are public
      # and show the users rigs first
      dropzone_id: [nil, dropzone_user.dropzone.id]
    ).order(is_public: :asc)
  }

  scope :reserve_in_date, -> {
    where(repack_expires_at: DateTime.current..)
  }

  before_save do
    assign_attributes(rig_type: :sport) if rig_type.blank?
  end

  def inspected_at?(dropzone)
    rig_inspections.joins(:inspected_by).exists?(inspected_by: { dropzone: dropzone })
  end
end
