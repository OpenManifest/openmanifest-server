# frozen_string_literal: true

# == Schema Information
#
# Table name: activity_types
#
#  id         :bigint           not null, primary key
#  name       :string
#  slug       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class ActivityType < ApplicationRecord
  include Config::Yaml::ActivityTypes

  has_many :permitted_activities
  has_many :certification_levels, through: :permitted_activities

  class << self
    # Find the intersection of jump types allowed for a set of users
    #
    # @param [Array<Membership>] memberships
    # @return [ActiveRecord::Collection<ActivityType>]
    def allowed_for(memberships)
      activity_type_ids = [memberships].flatten.map do |dz_user|
        dz_user.permitted_activities.pluck(:activity_type_id)
      end
      ActivityType.where(id: activity_type_ids.reduce(&:intersection))
    end
  end

  def allowed_for?(membership)
    ActivityType.allowed_for([membership].flatten).exists?(id: id)
  end
end
