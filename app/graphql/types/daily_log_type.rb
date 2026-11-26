# frozen_string_literal: true

module Types
  class DailyLogType < Types::Base::Object
    field :id, GraphQL::Types::ID, null: false
    field :notes, String, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :loads, [Types::Manifest::Load], null: true
    field :duty_officer, [Types::Users::Membership], null: true

    field :operator, Types::OperatorType, null: true
  end
end
