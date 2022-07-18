# frozen_string_literal: true

class Types::Events::EventType < Types::BaseObject
  field :id, GraphQL::Types::ID, null: false
  field :action, Types::Events::EventActionType, null: true
  field :message, String, null: true
  field :resource, Types::AnyResourceType, null: true
  field :dropzone_user, Types::DropzoneUserType, null: true
  field :level, Types::Events::EventLevelType, null: true
end
