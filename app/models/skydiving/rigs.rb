# frozen_string_literal: true

# What only skydiving knows about its equipment: the `rig` kind with its type (student, sport, tandem), the canopy size
# and the wing loading. It works on the generic equipment of that kind and is reached only by operators that have it.
module Skydiving
  module Rigs
    KIND = "rig"
    SQUARE_FEET_PER_SQUARE_METRE = 1 / Units::FACTORS.dig("area", "ft2")
    POUNDS_PER_KILOGRAM = 1 / Units::POUND

    module_function

    def student(operator) = of_type(operator, "student")

    def tandem(operator) = of_type(operator, "tandem")

    # The rigs of the operator with this type
    def of_type(operator, type)
      Equipment.kept.where(operator_id: operator.id).of_kind(KIND).where("equipment.properties ->> 'rig_type' = ?", type)
    end

    # Pounds per square foot of canopy, for a jumper of body_mass_kg (and the passenger of a tandem) under the rig
    #
    # @return [Float, nil]
    def wing_loading(rig, body_mass_kg)
      canopy_m2 = rig&.properties&.dig("canopy_size_m2")
      return if canopy_m2.blank? || body_mass_kg.blank?

      (body_mass_kg * POUNDS_PER_KILOGRAM) / (canopy_m2 * SQUARE_FEET_PER_SQUARE_METRE)
    end
  end
end
