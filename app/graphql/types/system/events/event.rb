# frozen_string_literal: true

class Types::System::Events::Event < Types::Base::Object
  field :id, GraphQL::Types::ID, null: false

  field :level, Types::System::Events::EventLevel, null: true
  field :action, Types::System::Events::EventAction, null: true
  field :details, String, null: true
  field :message, String, null: true

  async_field :created_by, Types::Users::Membership, null: true
  polymorphic_field :resource
  timestamp_fields
end
