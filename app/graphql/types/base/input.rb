# frozen_string_literal: true

module Types::Base
  class Input < GraphQL::Schema::InputObject
    argument_class Types::Base::Argument

    class_attribute :money_arguments, default: []

    # An amount of money: `<name>Cents`, an integer number of cents, and `<name>`, the same in whole units as before
    # (kept for older clients). When both are sent the cents are used.
    def self.money_argument(name, required: false, description: nil)
      argument :"#{name}_cents", Integer, required: false, description: ["In cents", description].compact.join(". ")
      argument name, Float, required: required, description: ["In whole units, use #{name.to_s.camelize(:lower)}Cents", description].compact.join(". ")
      self.money_arguments += [name]
    end

    def to_h
      super.tap do |hash|
        money_arguments.each { |name| hash.delete(name) if hash.key?(:"#{name}_cents") }
      end
    end
  end
end
