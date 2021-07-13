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
