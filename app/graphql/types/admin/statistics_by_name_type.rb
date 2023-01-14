# frozen_string_literal: true

class Types::Admin::StatisticsByNameType < Types::Base::Object
  field :count, Integer, null: false
  field :name, String, null: false
end
