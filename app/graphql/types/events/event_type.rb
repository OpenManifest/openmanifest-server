# frozen_string_literal: true

class Types::Events::EventType < Types::BaseObject
  field :id, GraphQL::Types::ID, null: false
  field :action, Types::Events::EventActionType, null: true
  field :message, String, null: true
  field :details, String, null: true
  field :resource, Types::AnyResourceType, null: true
  def resource
    return nil unless object.resource_id
    return nil unless Types::AnyResourceType.resolve_type(object.resource, context)
    object.resource
  end
  field :created_by, Types::DropzoneUserType, null: true
  field :created_at, GraphQL::Types::ISO8601DateTime, null: true
  field :level, Types::Events::EventLevelType, null: true
end
