# frozen_string_literal: true

module Types::System
  class FieldError < Types::Base::Object
    field :field, String, null: false
    field :message, String, null: false
  end
end
