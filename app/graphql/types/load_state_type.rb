# frozen_string_literal: true

class Types::LoadStateType < Types::BaseEnum
  Load.states.each do |name,|
    value name.to_s, name.to_s
  end
end
