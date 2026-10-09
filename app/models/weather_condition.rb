# frozen_string_literal: true

# == Schema Information
#
# Table name: weather_conditions
#
#  id               :bigint           not null, primary key
#  winds            :text
#  temperature      :integer
#  jump_run         :integer
#  exit_spot_miles  :decimal(6, 2)
#  offset_miles     :decimal(6, 2)
#  date             :date             not null
#  offset_direction :integer
#  dropzone_id      :bigint           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
class WeatherCondition < ApplicationRecord
  belongs_to :dropzone

  WINDS_URL = "https://markschulze.net/winds/winds.php"
  WINDS_TIMEOUT = 5 # seconds

  before_validation :set_date, on: :create
  before_create :set_defaults
  # The winds come from an external service: fetched by a job, the record exists without them until it has run
  after_create_commit :fetch_winds_later

  def guesstimate_jumprun
    # https://startskydiving.com/wp-content/uploads/2016/04/CategoryE.pdf
    # The effect of winds during canopy descent:
    # a. A canopy descends at approximately 1,000 feet per minute.
    # b. Divide the opening altitude by 1,000 feet to determine time of descent, e.g., 3,000 feet = three
    #    minutes of descent.
    # c. Estimate in miles per minute the amount of drift during descent, as in Table E.1:

    # Estimate rough opening height 3500 = 3.5min canopy

    # Average wind direction from 4000ft
    canopy_winds = JSON.parse(winds).filter_map { |wind| wind if wind["altitude"].to_i < 5000 }

    avg_direction = canopy_winds.sum { |wind| wind["direction"].to_i } / canopy_winds.count
    # Average wind speed from 4000ft
    avg_speed_knots = canopy_winds.sum { |wind| wind["speed"].to_i } / canopy_winds.count

    avg_speed_miles = avg_speed_knots * 1.15078

    # Calculate drift for 3.5min
    avg_drift_per_minute = avg_speed_miles / 60

    avg_drift_distance_miles = (avg_drift_per_minute * 3.5).round(2)

    # Calculate freefall drift
    freefall_winds = JSON.parse(winds).filter_map { |wind| wind if wind["altitude"].to_i > 4000 }

    avg_fall_direction = freefall_winds.sum { |wind| wind["direction"].to_i } / freefall_winds.count
    # Average wind speed from 4000ft
    avg_fall_speed_knots = freefall_winds.sum { |wind| wind["speed"].to_i } / freefall_winds.count

    avg_fall_speed_miles = avg_fall_speed_knots * 1.15078

    # Calculate drift for 3.5min
    avg_fall_drift_per_minute = avg_fall_speed_miles / 60

    avg_fall_drift_distance_miles = (avg_fall_drift_per_minute * 3.5).round(2)

    avg_dir = (avg_fall_direction + avg_direction) / 2
    avg_drift = (avg_fall_drift_distance_miles + avg_drift_distance_miles) / 2

    rounded_avg_dir = ((avg_dir / 5.0).round(0) * 5.0).to_i

    assign_attributes(jump_run: rounded_avg_dir, exit_spot_miles: avg_drift)
  rescue JSON::ParserError, ZeroDivisionError, TypeError
    nil
  end

  # Fetches the winds for a place and stores them with the jump run they give (it does not save). Network errors are
  # raised: FetchWindsJob retries them.
  def from_coordinates(lat, lng)
    response = HTTParty.get(
      WINDS_URL,
      query: { lat: lat, lon: lng, hourOffset: 0, referrer: "openmanifestorg" },
      timeout: WINDS_TIMEOUT
    )
    data = JSON.parse(response.body)

    winds = [0, 1000, 2000, 5000, 7000, 8000, 10000, 12000, 14000].map(&:to_s).reverse.map do |alt|
      {
        altitude: alt,
        speed: data["speed"][alt],
        direction: data["direction"][alt],
        temperature: data["temp"][alt],
      }
    end

    assign_attributes(winds: winds.to_json, temperature: winds.last[:temperature] || 0)
    guesstimate_jumprun
  end

  private

  def set_date
    self.date ||= dropzone&.today
  end

  def fetch_winds_later
    FetchWindsJob.perform_later(id) if dropzone.lat.present? && dropzone.lng.present?
  end

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
