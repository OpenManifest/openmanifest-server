# frozen_string_literal: true

class Types::Events::EventLevelType < Types::BaseEnum
  Event.levels.each do |name,|
    value name.to_s, name.to_s
  end
end
