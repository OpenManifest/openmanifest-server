# Create Jump types
[
  ["Angle/Tracking", "angle"],
  ["Camera", "cam"],
  ["Freefly", "freefly"],
  ["Hop n Pop", "hnp"],
  ["High-pull", "hp"],
  ["Flat", "fs"],
  ["Wingsuit", "ws"],
].each do |type|
  name, slug = type
  JumpType.find_or_create_by(
    name: name,
    slug: slug
  )
end