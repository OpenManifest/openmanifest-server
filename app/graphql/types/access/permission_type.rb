# frozen_string_literal: true

class Types::Access::PermissionType < Types::Base::Enum
  ::Permission.slugs.each do |name,|
    value name
  end
end
