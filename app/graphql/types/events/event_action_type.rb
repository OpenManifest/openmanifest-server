# frozen_string_literal: true

class Types::Events::EventActionType < Types::BaseEnum
  ::Activity::Event.actions.each do |name,|
    value name.to_s, name.to_s
  end
end
