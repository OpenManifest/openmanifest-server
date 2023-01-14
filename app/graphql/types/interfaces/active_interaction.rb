# frozen_string_literal: true

module Types::Interfaces
  module ActiveInteraction
    include Types::Base::Interface
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true

    def mutate(interaction, field_name, on_success: nil, **opts)
      # If we need an access context, but don't have one, try to infer it
      # To infer it we need the user and a dropzone or a dropzone ID
      if interaction.filters.key?(:access_context) && !opts.key?(:access_context) && dropzone_or_dropzone_id = opts[:dropzone] || opts[:dropzone_id]
        case dropzone_or_dropzone_id
        when ApplicationRecord
          opts[:access_context] = access_context_for(
            dropzone_or_dropzone_id
          )
        when Integer
          opts[:access_context] = access_context_for(
            dropzone_or_dropzone_id
          )
        end
      end
      outcome = interaction.run(**opts)

      if outcome.valid?
        {
          field_name => outcome.result,
          error: nil,
          field_errors: nil,
        }
      else
        {
          field_name => nil,
          field_errors: outcome.errors.to_hash.except(:base).map do |field, message|
                          { field: field, message: [message].flatten.compact_blank.first }
                        end,
          errors: outcome.errors.full_messages_for(:base),
        }
      end
    rescue ::ApplicationInteraction::Errors::PermissionDenied => e
      {
        field_name => nil,
        field_errors: nil,
        errors: [e.message],
      }
    end
  end
end
