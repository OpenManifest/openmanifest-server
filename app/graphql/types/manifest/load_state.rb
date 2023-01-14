# frozen_string_literal: true

class Types::Manifest::LoadState < Types::Base::Enum
  Load.states.each do |name,|
    value name.to_s, name.to_s
  end
end
