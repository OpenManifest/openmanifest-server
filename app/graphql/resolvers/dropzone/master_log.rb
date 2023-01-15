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
    entry = dropzone.master_logs.at(date)
    return nil unless entry
    entry.generate_json.merge(
      download_url: entry.download_url
    )
  end
end
