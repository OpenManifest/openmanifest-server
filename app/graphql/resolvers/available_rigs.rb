# frozen_string_literal: true

class Resolvers::AvailableRigs < Resolvers::Base
  description "Get user rigs that have been inspected and marked as OK + dropzone rigs"
  type [Types::RigType], null: true
  argument  :dropzone_user,    Integer, required: true,
            description: "Dropzone User to get rigs for",
            prepare: -> (value, ctx) { DropzoneUser.find(value) }
  argument  :is_tandem,        Boolean, required: false
  argument  :load_id,          Integer, required: false,
            description: "Filter out rigs already occupied for a load"
  def resolve(
    dropzone_user: nil,
    is_tandem: nil,
    load_id: nil,
    lookahead: nil
  )
    return dropzone_user.dropzone.tandem_rigs if is_tandem

    dropzone_user.available_rigs(load_id: load_id)
  end
end
