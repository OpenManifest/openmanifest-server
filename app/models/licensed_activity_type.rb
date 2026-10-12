# frozen_string_literal: true

# == Schema Information
#
# Table name: licensed_activity_types
#
#  id           :bigint           not null, primary key
#  license_id   :bigint           not null
#  activity_type_id :bigint           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class LicensedActivityType < ApplicationRecord
  belongs_to :license
  belongs_to :activity_type
end
