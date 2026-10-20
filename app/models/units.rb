# frozen_string_literal: true

# Quantities are stored in SI and shown in the operator's units (GENERALISATION §12): altitude and depth in metres,
# distance in metres, mass in kilograms, area in square metres, speed in metres per second, temperature in degrees Celsius.
# The API takes and gives SI only; the client converts at the edge. `to_si` and `from_si` are the conversions of this
# module, the same pairs as the client's (`app/i18n/units.ts`).
module Units
  FOOT = 0.3048
  NAUTICAL_MILE = 1852.0
  MILE = 1609.344
  POUND = 0.45359237

  # Metres, kilograms, ... in one unit of each (temperature is not a ratio: see TEMPERATURE)
  FACTORS = {
    "altitude" => { "m" => 1.0, "ft" => FOOT },
    "depth" => { "m" => 1.0, "ft" => FOOT },
    "distance" => { "m" => 1.0, "km" => 1000.0, "nmi" => NAUTICAL_MILE, "mi" => MILE },
    "mass" => { "kg" => 1.0, "lb" => POUND },
    "area" => { "m2" => 1.0, "ft2" => FOOT * FOOT },
    "speed" => { "mps" => 1.0, "kn" => NAUTICAL_MILE / 3600.0, "kmh" => 1 / 3.6, "mph" => MILE / 3600.0 },
  }.freeze

  TEMPERATURE = %w(c f).freeze

  # The units an operator can choose for a quantity (the SI unit of speed is not one of them)
  CHOICES = FACTORS.transform_values { |units| units.keys.without("mps") }.merge("temperature" => TEMPERATURE).freeze

  class UnknownUnit < ArgumentError; end

  module_function

  def quantities = CHOICES.keys

  def supported(quantity) = CHOICES.fetch(quantity.to_s)

  def valid?(quantity, unit) = CHOICES.fetch(quantity.to_s, []).include?(unit.to_s)

  # A value in `unit` as SI
  def to_si(quantity, value, unit)
    return if value.nil?
    return celsius(value, unit) if quantity.to_s == "temperature"

    value * factor(quantity, unit)
  end

  # An SI value in `unit`
  def from_si(quantity, value, unit)
    return if value.nil?
    return fahrenheit(value, unit) if quantity.to_s == "temperature"

    value / factor(quantity, unit)
  end

  def convert(quantity, value, from:, to:) = from_si(quantity, to_si(quantity, value, from), to)

  def factor(quantity, unit)
    FACTORS.fetch(quantity.to_s).fetch(unit.to_s) { raise UnknownUnit, "#{unit.inspect} is not a unit of #{quantity}" }
  end

  def celsius(value, unit)
    case unit.to_s
    when "c" then value
    when "f" then (value - 32) * 5.0 / 9
    else raise UnknownUnit, "#{unit.inspect} is not a unit of temperature"
    end
  end

  def fahrenheit(value, unit)
    case unit.to_s
    when "c" then value
    when "f" then (value * 9.0 / 5) + 32
    else raise UnknownUnit, "#{unit.inspect} is not a unit of temperature"
    end
  end
end
