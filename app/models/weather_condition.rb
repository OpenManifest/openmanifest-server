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
class WeatherCondition < ApplicationRecord
  belongs_to :dropzone
  before_create :set_defaults

  private
    def set_defaults
      assign_attributes(
        winds: [
          { altitude: 14000, wind: 0, direction: 0 },
          { altitude: 10000, wind: 0, direction: 0 },
          { altitude: 7000, wind: 0, direction: 0 },
          { altitude: 5000, wind: 0, direction: 0 },
          { altitude: 2000, wind: 0, direction: 0 },
        ].to_json,
        temperature: 0,
        offset_miles: 0,
      )
    end
end
