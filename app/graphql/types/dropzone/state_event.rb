# frozen_string_literal: true

class Types::Dropzone::StateEvent < Types::BaseEnum
  graphql_name "DropzoneStateEvent"
  ::Dropzone.state_machine.events.keys.each do |state|
    value state, state
  end
end
