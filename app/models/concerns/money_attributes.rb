# frozen_string_literal: true

# Money attributes stored as integer cents. `money :credits` on a model with a `credits_cents` column gives
#
# - `credits_cents`, the amount in cents: what the database holds and the API gives
# - `credits`, the amount in whole units as a Float (12.5), for code that works in units (seeds, factories, specs);
#   setting it rounds to the cent
#
# There is no column of units. Wallets change with `add_cents!`, atomically in SQL.
module MoneyAttributes
  extend ActiveSupport::Concern

  included do
    class_attribute :money_attribute_names, instance_writer: false, default: []
  end

  class_methods do
    def money(*names)
      self.money_attribute_names = (money_attribute_names + names.map(&:to_sym)).uniq

      names.each do |name|
        cents = :"#{name}_cents"

        define_method(name) { self[cents]&./(100.0) }

        define_method(:"#{name}=") { |units| public_send(:"#{cents}=", Money.cents_of(units)) }

        define_method(:"#{cents}=") { |value| write_attribute(cents, value) }
      end
    end
  end

  # Adds `delta` cents to a money attribute, in one atomic UPDATE (two requests adding at once both count), and keeps this
  # object current
  def add_cents!(name, delta)
    name = name.to_sym
    raise ArgumentError, "#{name} is not a money attribute of #{self.class.name}" unless money_attribute_names.include?(name)

    cents = :"#{name}_cents"
    delta = Integer(delta)
    table = self.class.arel_table
    total = Arel::Nodes::NamedFunction.new("COALESCE", [table[cents], Arel::Nodes.build_quoted(0)]) + delta
    self.class.where(id: id).update_all(cents => total)
    # What the row holds now, without marking the attribute as changed (a later save must not write it back)
    write_attribute(cents, self.class.where(id: id).pick(cents))
    clear_attribute_changes([cents.to_s])
    self
  end
end
