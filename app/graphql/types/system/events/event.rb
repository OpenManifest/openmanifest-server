# frozen_string_literal: true

class Types::System::Events::Event < Types::Base::Object
  lookahead do |query|
    query = query.includes(:created_by) if selects?(:created_by)
    query
  end
  field :id, GraphQL::Types::ID, null: false

  field :level, Types::System::Events::EventLevel, null: true
  field :action, Types::System::Events::EventAction, null: true
  field :details, String, null: true
  field :message, String, null: true

  async_field :created_by, Types::Users::DropzoneUser, null: true
  polymorphic_field :resource
  timestamp_fields
end
