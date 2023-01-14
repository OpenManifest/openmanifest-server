# frozen_string_literal: true

class Types::System::Events::EventLevel < Types::Base::Enum
  Activity::Event.levels.each do |name,|
    value name.to_s, name.to_s
  end
end
