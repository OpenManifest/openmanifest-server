# frozen_string_literal: true

class Types::ModerationRoleType < Types::BaseEnum
  User.moderation_roles.keys.each do |name,|
    value name.to_s, name.to_s
  end
end
