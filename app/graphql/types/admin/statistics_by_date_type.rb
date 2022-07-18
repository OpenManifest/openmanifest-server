# frozen_string_literal: true

class Types::Admin::StatisticsByDateType < Types::BaseObject
  field :date, GraphQL::Types::ISO8601Date, null: false
  field :count, Integer, null: false
end
