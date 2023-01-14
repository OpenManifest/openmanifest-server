# frozen_string_literal: true

module Types
  module Input
    class LoadInput < Types::Base::Input
      argument :name, String, required: false
      argument :max_slots, Int, required: false
      argument :pilot, Int, required: false,
                            prepare: -> (value, ctx) { ::DropzoneUser.find_by(id: value) }
      argument :dispatch_at, GraphQL::Types::ISO8601DateTime, required: false,
                                                              prepare: -> (value, ctx) { value ? value.to_datetime : nil }
      argument :plane, Int, required: false,
                            prepare: -> (value, ctx) { ::Plane.find_by(id: value) }
      argument :gca, Int, required: false,
                          prepare: -> (value, ctx) { ::DropzoneUser.find_by(id: value) }
      argument :load_master, Int, required: false,
                                  prepare: -> (value, ctx) { ::DropzoneUser.find_by(id: value) }
      argument :state, Types::Manifest::LoadState, required: false
    end
  end
end
