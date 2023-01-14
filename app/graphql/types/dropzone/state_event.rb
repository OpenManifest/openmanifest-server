# frozen_string_literal: true

class Types::Dropzone::StateEvent < Types::Base::Enum
  graphql_name "DropzoneStateEvent"
  ::Dropzone.state_machine.events.keys.each do |state|
    value state.to_s, state.to_s
  end
end
