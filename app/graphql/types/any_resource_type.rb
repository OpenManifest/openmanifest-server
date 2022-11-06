# frozen_string_literal: true

module Types
  module AnyResourceType
    include Types::BaseInterface
    field :id, ID, null: false
    field :guid, ID, null: false
    def guid
      object.to_gid_param
    end
  end
end
