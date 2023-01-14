# frozen_string_literal: true

class Types::Users::ModerationRole < Types::Base::Enum
  User.moderation_roles.keys.each do |name,|
    value name.to_s, name.to_s
  end
end
