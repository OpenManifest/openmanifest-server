# frozen_string_literal: true

module Types
  module InteractionMutationInterface
    include BaseInterface
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    def mutate(interaction, field_name, on_success: nil, **opts)
      outcome = interaction.run(**opts)

      if outcome.valid?
        on_success(opts[:on_success], outcome.result) if opts.key?(:on_success)
        {
          field_name => outcome.result,
          error: nil,
          field_errors: nil
        }
      else
        {
          field_name => nil,
          field_errors: outcome.errors.to_hash.except(:base).map { |field, message| { field: field, message: message } },
          errors: outcome.errors.full_messages_for(:base)
        }
      end
    end

    def on_success(symbol_or_proc, outcome)
      if symbol_or_proc.is_a?(Symbol)
        send(symbol_or_proc, outcome) if defined?(symbol_or_proc)
      elsif symbol_or_proc.is_a?(Proc)
        symbol_or_proc.call(outcome)
      end
    end
  end
end
