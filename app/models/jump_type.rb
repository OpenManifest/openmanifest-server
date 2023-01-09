# frozen_string_literal: true

# == Schema Information
#
# Table name: jump_types
#
#  id         :bigint           not null, primary key
#  name       :string
#  slug       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class JumpType < ApplicationRecord
  include Config::Yaml::JumpTypes
  has_many :licensed_jump_types
  has_many :licenses, through: :licensed_jump_types

  class << self
    # Find the intersection of jump types allowed for a set of users
    #
    # @param [Array<DropzoneUser>] dropzone_users
    # @return [ActiveRecord::Collection<JumpType>]
    def allowed_for(dropzone_users)
      jump_type_ids = [dropzone_users].flatten.map do |dz_user|
        dz_user.licensed_jump_types.pluck(:jump_type_id)
      end
      JumpType.where(id: jump_type_ids.reduce(&:intersection))
    end
  end

  def allowed_for?(dropzone_user)
    JumpType.allowed_for([dropzone_user].flatten).exists?(id: id)
  end
end
