# frozen_string_literal: true

# == Schema Information
#
# Table name: weather_conditions
#
#  id               :bigint           not null, primary key
#  winds            :text
#  temperature      :integer
#  jump_run         :integer
#  exit_spot_miles  :integer
#  offset_miles     :integer
#  offset_direction :integer
#  dropzone_id      :bigint           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
require 'rails_helper'

RSpec.describe WeatherCondition, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
