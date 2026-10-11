# frozen_string_literal: true

class Resolvers::Dropzone::MasterLog < Resolvers::Base
  description "Get the master log entry for a specific day"
  type Types::Dropzone::MasterLogEntry, null: true

  dropzone :dropzone, required: true

  argument :date, GraphQL::Types::ISO8601Date,
           required: true,
           prepare: -> (value, ctx) { value.to_date }

  def resolve(
    dropzone: nil,
    date: nil,
    lookahead: nil
  )
    return nil unless dropzone

    # The same permission that lets a user write the master log (and that shows its menu entry in the app)
    authorize_dropzone!(dropzone, :updateDropzone)
    dropzone.master_logs.at(date)
  end
end
