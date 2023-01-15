# frozen_string_literal: true

module Mutations::Dropzone
  class UpdateMasterLog < Mutations::BaseMutation
    field :errors, [String], null: true
    field :master_log, Types::Dropzone::MasterLogEntry, null: true
    field :field_errors, [Types::System::FieldError], null: true

    argument :attributes, Types::Dropzone::MasterLog::MasterLogInput, required: true
    argument :date, GraphQL::Types::ISO8601Date, required: true,
                                                 prepare: -> (value, ctx) { value.to_date }
    argument :dropzone, ID, required: true,
                            prepare: -> (value, ctx) { Dropzone.find_by(id: value) }

    def resolve(attributes:, dropzone: nil, date: nil)
      Time.use_zone(dropzone.time_zone) do
        mutate(
          ::MasterLog::Update,
          :master_log,
          access_context: access_context_for(dropzone),
          date: date,
          dropzone: dropzone,
          **attributes.to_h.slice(
            :notes,
            :dzso,
          )
        )
      end
    end
  end
end
