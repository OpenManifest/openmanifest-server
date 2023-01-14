# frozen_string_literal: true

class Types::Dropzone::State < Types::Base::Enum
  graphql_name "DropzoneState"
  ::Dropzone.state_machine.states.keys.each do |state|
    value state
  end
end
