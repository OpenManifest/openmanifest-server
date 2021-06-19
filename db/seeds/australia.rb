# frozen_string_literal: true

# Make sure jump types exist
load(Rails.root.join("db", "seeds", "jump_types.rb"))
load(Rails.root.join("db", "seeds", "permissions.rb"))

# Create APF
apf = Federation.find_or_create_by(
  slug: "apf",
  name: "APF"
)


# Assign jump types to licenses
{
  "Certificate A" => ["hnp", "hp", "fs"],
  "Certificate B" => ["hnp", "hp", "fs", "angle", "freefly"],
  "Certificate C" => ["hnp", "hp", "fs", "angle", "freefly", "cam"],
  "Certificate D" => ["hnp", "hp", "fs", "angle", "freefly", "cam", "wingsuit"],
  "Certificate E" => ["hnp", "hp", "fs", "angle", "freefly", "cam", "wingsuit"],
  "Certificate F" => ["hnp", "hp", "fs", "angle", "freefly", "cam", "wingsuit"],
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
