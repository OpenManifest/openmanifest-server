# frozen_string_literal: true

module Mutations::Operator
  class UpdateDailyLog < Mutations::BaseMutation
    field :errors, [String], null: true
    field :daily_log, Types::Operator::DailyLogEntry, null: true
    field :field_errors, [Types::System::FieldError], null: true

    argument :attributes, Types::Operator::DailyLog::DailyLogInput, required: true
    argument :date, GraphQL::Types::ISO8601Date, required: true,
                                                 prepare: -> (value, ctx) { value.to_date }
    argument :operator, ID, required: true,
                            prepare: -> (value, ctx) { Operator.find_by(id: value) }

    def resolve(attributes:, operator: nil, date: nil)
      Time.use_zone(operator.time_zone) do
        mutate(
          ::DailyLog::Update,
          :daily_log,
          access_context: access_context_for(operator),
          date: date,
          operator: operator,
          **attributes.to_h.slice(
            :notes,
            :duty_officer,
          )
        )
      end
    end
  end
end
