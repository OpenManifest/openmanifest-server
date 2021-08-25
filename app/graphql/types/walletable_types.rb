# frozen_string_literal: true

class Types::WalletableTypes < Types::BaseEnum
  [
    DropzoneUser,
    Dropzone
  ].map do |model|
    value model.name.camelize(:lower), value: model.name
  end
end
