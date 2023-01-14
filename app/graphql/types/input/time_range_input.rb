# frozen_string_literal: true

class Types::Input::TimeRangeInput < Types::Base::Input
  argument :start_time, GraphQL::Types::ISO8601DateTime, required: false,
                                                         prepare: -> (value, ctx) { value.to_datetime }
  argument :end_time, GraphQL::Types::ISO8601DateTime, required: false,
                                                       prepare: -> (value, ctx) { value.to_datetime }
end
