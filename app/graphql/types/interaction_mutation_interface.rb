# frozen_string_literal: true

module Types
  module InteractionMutationInterface
    include BaseInterface
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    def mutate(interaction, field_name, on_success: nil, **opts)
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
