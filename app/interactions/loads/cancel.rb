require 'active_interaction'

class Loads::Cancel < ActiveInteraction::Base
  integer :load_id
  validates :load_id, presence: true

  def execute
    set_load
    mark_as_cancelled
    refund_orders
    errors.merge!(@model.errors) unless @model.save
    @model
  end

  def set_load
    @model = Load.find(load_id)
  end

  def mark_as_cancelled
    @model.assign_attributes(state: :cancelled, is_open: false)
  end

  def refund_orders
    @model.slots.each do |slot|
      compose(
        ::Transactions::Refund,
        order: slot.order
      )
    end
  end
end
