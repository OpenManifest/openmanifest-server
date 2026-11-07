# frozen_string_literal: true

# == Schema Information
#
# Table name: permitted_activities
#
#  id                     :bigint           not null, primary key
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  activity_type_id       :bigint           not null
#  certification_level_id :bigint           not null
#
# What a level of a certification body allows its holder to do
class PermittedActivity < ApplicationRecord
  belongs_to :certification_level
  belongs_to :activity_type
end
