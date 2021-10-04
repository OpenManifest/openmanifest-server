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

  def from_coordinates(lat, lng)
    response = JSON.parse(
      URI.open(
        "https://markschulze.net/winds/winds.php?lat=#{lat}&lng=#{lng}&hourOffset=1&referrer=openmanifestorg"
      ).read
    )

    winds = [0, 1000, 2000, 5000, 7000, 8000, 10000, 12000, 14000].map(&:to_s).reverse.map do |alt|
      {
        altitude: alt,
        speed: response["speed"][alt],
        direction: response["direction"][alt],
        temperature: response["temp"][alt]
      }
    end

    assign_attributes(
      winds: winds.to_json,
      temperature: if winds.count
                     winds.last['temperature'] || 0
                   else
                     0
                   end
    )
  rescue => e
    puts e.message
    nil
  end

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

      if dropzone.lat.present? && dropzone.lng.present?
        from_coordinates(dropzone.lat, dropzone.lng)
      end
    end
end
