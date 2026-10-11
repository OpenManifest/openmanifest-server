# frozen_string_literal: true

# Money attributes stored as integer cents. `money :credits` on a model with a `credits_cents` column gives
#
# - `credits_cents`, the amount in cents: what the database holds and the API gives
# - `credits`, the amount in whole units as a Float (12.5), as before, for the code and the clients that use it; setting it
#   rounds to the cent
#
# Writing either also writes the old column (`credits`, a Float or integer column of units), which stays current until it is
# dropped (P8.8). Wallets change with `add_cents!`, atomically in SQL.
module MoneyAttributes
  extend ActiveSupport::Concern

  class_methods do
    def money(*names)
      names.each do |name|
        cents = :"#{name}_cents"

        define_method(name) { self[cents]&./(100.0) }

        define_method(:"#{name}=") { |units| public_send(:"#{cents}=", Money.cents_of(units)) }

        define_method(:"#{cents}=") do |value|
          write_attribute(cents, value)
          write_attribute(name, value && (value / 100.0))
        end
      end
    end
  end

  # Adds `delta` cents to a money attribute, in one atomic UPDATE (two requests adding at once both count), and keeps the
  # old column and this object current
  def add_cents!(name, delta)
    cents = "#{name}_cents"
    delta = Integer(delta)
    self.class.where(id: id).update_all(["#{cents} = COALESCE(#{cents}, 0) + ?, #{name} = (COALESCE(#{cents}, 0) + ?) / 100.0", delta, delta])
    # What the row holds now, without marking the attributes as changed (a later save must not write them back)
    fresh = self.class.where(id: id).pick(cents, name)
    write_attribute(cents, fresh[0])
    write_attribute(name, fresh[1])
    clear_attribute_changes([cents.to_s, name.to_s])
    self
  end
end
