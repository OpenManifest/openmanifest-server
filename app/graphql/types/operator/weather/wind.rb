# frozen_string_literal: true

module Types::Operator::Weather
  # The wind at a height, in SI
  class Wind < Types::Base::Object
    field :altitude_m, Float, null: true, description: "Height above the ground, metres", hash_key: "altitude_m"
    field :speed_mps, Float, null: true, description: "Metres per second", hash_key: "speed_mps"
    field :direction, Int, null: true, hash_key: "direction"
    field :temperature_c, Float, null: true, description: "Degrees Celsius", hash_key: "temperature_c"
  end
end
