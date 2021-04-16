# frozen_string_literal: true

# Make sure jump types exist
load(Rails.root.join("db", "seeds", "jump_types.rb"))

# Create APF
apf = Federation.find_or_create_by(
  slug: "apf",
  name: "APF"
)

# Create licenses
["A", "B", "C", "D", "E", "F"].each do |license|
end



# Assign jump types to licenses
{
  A: ["hnp", "hp", "fs"],
  B: ["hnp", "hp", "fs", "angle", "freefly"],
  C: ["hnp", "hp", "fs", "angle", "freefly", "cam"],
  D: ["hnp", "hp", "fs", "angle", "freefly", "cam", "wingsuit"],
  E: ["hnp", "hp", "fs", "angle", "freefly", "cam", "wingsuit"],
  F: ["hnp", "hp", "fs", "angle", "freefly", "cam", "wingsuit"],
}.each do |(license_name, types)|
  license = License.find_or_create_by(
    name: license_name,
    federation: apf
  )

  types.each do |type|
    LicensedJumpType.find_or_create_by(
      license: license,
      jump_type: JumpType.find_by(slug: type)
    )
  end
end
