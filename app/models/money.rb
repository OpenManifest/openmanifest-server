# frozen_string_literal: true

# An amount of money in integer cents. The database and the API hold cents; arithmetic is done on cents, never on
# fractions of a unit (0.1 + 0.2 is not 0.3 in a Float, 10 + 20 is 30 in cents).
class Money
  include Comparable

  attr_reader :cents

  # The cents of an amount in whole units: 12.5 (or "12.50", or a BigDecimal) is 1250
  def self.cents_of(units)
    return if units.nil?

    (BigDecimal(units.to_s) * 100).round.to_i
  end

  def self.from_units(units)
    new(cents_of(units))
  end

  def initialize(cents)
    @cents = Integer(cents)
  end

  def +(other)
    self.class.new(cents + other.cents)
  end

  def -(other)
    self.class.new(cents - other.cents)
  end

  def -@
    self.class.new(-cents)
  end

  def abs
    self.class.new(cents.abs)
  end

  # Whole units as a Float, for display and for the fields kept for older clients
  def to_f
    cents / 100.0
  end

  def <=>(other)
    cents <=> other.cents if other.is_a?(Money)
  end

  def zero?
    cents.zero?
  end

  # "$12.50", "-$3.00"
  def to_s
    sign = cents.negative? ? "-" : ""
    units, remainder = cents.abs.divmod(100)
    format("%s$%d.%02d", sign, units, remainder)
  end
end
