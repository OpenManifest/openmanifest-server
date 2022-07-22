# frozen_string_literal: true

class Types::Admin::StatisticsByNameType < Types::BaseObject
  field :name, String, null: false
  field :count, Integer, null: false
end
