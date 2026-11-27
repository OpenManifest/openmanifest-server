# frozen_string_literal: true

class Types::Payments::Walletable < Types::Base::Enum
  [
    Membership,
    Operator,
  ].map do |model|
    value model.name.camelize(:lower), value: model.name
  end
end
