# frozen_string_literal: true

module Types::Base
  class Input < GraphQL::Schema::InputObject
    argument_class Types::Base::Argument

    # An amount of money: `<name>Cents`, an integer number of cents
    def self.money_argument(name, required: false, description: nil)
      argument :"#{name}_cents", Integer, required: required, description: ["In cents", description].compact.join(". ")
    end
  end
end
