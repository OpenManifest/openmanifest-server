# frozen_string_literal: true

module Types
  module InteractionMutationInterface
    include BaseInterface
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    def mutate(interaction, field_name, on_success: nil, **opts)
      # If we need an access context, but don't have one, try to infer it
      # To infer it we need the user and a dropzone or a dropzone ID
      if interaction.filters.keys.include?(:access_context) && !opts.keys.include?(:access_context)
        if dropzone_or_dropzone_id = opts[:dropzone] || opts[:dropzone_id]
          if dropzone_or_dropzone_id.is_a?(ApplicationRecord)
            opts.merge!(
              access_context: access_context_for(
                dropzone_or_dropzone_id
              ),
            )
          elsif dropzone_or_dropzone_id.is_a?(Integer)
            opts.merge!(
              access_context: access_context_for(
                dropzone_or_dropzone_id
              )
            )
          end
        end
      end
      outcome = interaction.run(**opts)

      if outcome.valid?
        {
          field_name => outcome.result,
          error: nil,
          field_errors: nil
        }
      else
        {
          field_name => nil,
          field_errors: outcome.errors.to_hash.except(:base).map { |field, message| { field: field, message: [message].flatten.reject(&:blank?).first } },
          errors: outcome.errors.full_messages_for(:base)
        }
      end
    rescue ::ApplicationInteraction::Errors::PermissionDenied => e
      {
        field_name => nil,
        field_errors: nil,
        errors: [e.message]
      }
    end
  end
end
