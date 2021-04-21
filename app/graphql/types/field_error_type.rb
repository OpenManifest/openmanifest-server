# frozen_string_literal: true

module Types
  class FieldErrorType < Types::BaseObject
    field :field, String, null: false
    field :message, String, null: false
  end
end
