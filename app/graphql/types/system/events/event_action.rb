# frozen_string_literal: true

class Types::System::Events::EventAction < Types::Base::Enum
  ::Activity::Event.actions.each do |name,|
    value name.to_s, name.to_s
  end
end
