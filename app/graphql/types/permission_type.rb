# frozen_string_literal: true

class Types::PermissionType < Types::BaseEnum
  Permission.names.each do |name,|
    value name
  end
end
