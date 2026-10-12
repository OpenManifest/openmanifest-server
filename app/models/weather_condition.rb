# frozen_string_literal: true

# == Schema Information
#
# Table name: weather_conditions
#
#  id               :bigint           not null, primary key
#  winds            :text
#  temperature_c    :decimal(5, 1)
#  jump_run         :integer
#  exit_spot_m      :decimal(10, 2)
#  offset_m         :decimal(10, 2)
#  date             :date             not null
#  offset_direction :integer
#  operator_id      :bigint           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
class WeatherCondition < ApplicationRecord
  belongs_to :operator

  WINDS_URL = "https://markschulze.net/winds/winds.php"
  WINDS_TIMEOUT = 5 # seconds

  before_validation :set_date, on: :create
  before_create :set_defaults
  # The winds come from an external service: fetched by a job, the record exists without them until it has run
  after_create_commit :fetch_winds_later

  # Winds as they are stored (SI): `[{ altitude_m:, speed_mps:, direction:, temperature_c: }]`
  def wind_list = JSON.parse(winds || "[]")

  # The drift of a canopy and of the freefall under the winds of the day gives the jump run (the direction, to 5 degrees)
  # and the distance of the exit from the spot. A canopy comes down at about 1,000 feet a minute, so the 3,500 feet an
  # opening is high above the ground take 3.5 minutes, and the freefall is counted over the same time.
  # https://startskydiving.com/wp-content/uploads/2016/04/CategoryE.pdf
  CANOPY_MINUTES = 3.5
  CANOPY_CEILING_M = 5000 * Units::FOOT
  FREEFALL_FLOOR_M = 4000 * Units::FOOT

  def guesstimate_jumprun
    list = wind_list
    canopy_winds = list.select { |wind| wind["altitude_m"].to_f < CANOPY_CEILING_M }
    freefall_winds = list.select { |wind| wind["altitude_m"].to_f > FREEFALL_FLOOR_M }

    canopy_direction, canopy_drift = drift(canopy_winds)
    freefall_direction, freefall_drift = drift(freefall_winds)

    direction = (canopy_direction + freefall_direction) / 2
    assign_attributes(jump_run: ((direction / 5.0).round * 5), exit_spot_m: ((canopy_drift + freefall_drift) / 2).round(2))
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

    # The service answers in feet and knots, by height
    winds = [0, 1000, 2000, 5000, 7000, 8000, 10000, 12000, 14000].map(&:to_s).reverse.map do |alt|
      {
        altitude_m: Units.to_si("altitude", alt.to_f, "ft").round(2),
        speed_mps: Units.to_si("speed", data["speed"][alt].to_f, "kn").round(2),
        direction: data["direction"][alt],
        temperature_c: data["temp"][alt],
      }
    end

    assign_attributes(winds: winds.to_json, temperature_c: winds.last[:temperature_c] || 0)
    guesstimate_jumprun
  end

  private

  def set_date
    self.date ||= operator&.today
  end

  def fetch_winds_later
    FetchWindsJob.perform_later(id) if operator.lat.present? && operator.lng.present?
  end

  # The average direction (degrees) of these winds, and how far they carry something in 3.5 minutes (metres)
  def drift(list)
    direction = list.sum { |wind| wind["direction"].to_i } / list.count
    speed_mps = list.sum { |wind| wind["speed_mps"].to_f } / list.count
    [direction, speed_mps * 60 * CANOPY_MINUTES]
  end

  def set_defaults
    assign_attributes(
      winds: [14_000, 10_000, 7000, 5000, 2000].map do |feet|
        { altitude_m: Units.to_si("altitude", feet, "ft").round(2), speed_mps: 0, direction: 0, temperature_c: 0 }
      end.to_json,
      temperature_c: 0,
      offset_m: 0,
    )
  end
end
