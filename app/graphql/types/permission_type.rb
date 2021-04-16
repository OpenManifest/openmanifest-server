# frozen_string_literal: true

class Types::PermissionType < Types::BaseEnum
  Permission.names.each do |name,|
    value name.to_s, name.to_s
  end
end
