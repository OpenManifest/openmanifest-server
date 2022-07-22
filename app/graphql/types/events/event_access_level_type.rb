# frozen_string_literal: true

class Types::Events::EventAccessLevelType < Types::BaseEnum
  Activity::Event.access_levels.each do |name,|
    value name.to_s, name.to_s
  end
end
