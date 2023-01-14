# frozen_string_literal: true

class Types::Admin::StatisticsByDateType < Types::Base::Object
  field :count, Integer, null: false
  field :date, GraphQL::Types::ISO8601Date, null: false
end
