# frozen_string_literal: true

class Types::Payments::Walletable < Types::Base::Enum
  [
    DropzoneUser,
    Dropzone,
  ].map do |model|
    value model.name.camelize(:lower), value: model.name
  end
end
