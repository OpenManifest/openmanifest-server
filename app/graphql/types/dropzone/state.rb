class Types::Dropzone::State < Types::BaseEnum
  graphql_name 'DropzoneState'
  Dropzone.state_machine.states.keys.each do |state|
    value state
  end
end