# frozen_string_literal: true

require "active_interaction"

class Loads::Finalize < ActiveInteraction::Base
  integer :load_id
  validates :load_id, presence: true

  def execute
    set_load
    mark_as_landed
    finalize_orders
    errors.merge!(@model.errors) unless @model.save
    @model
  end

  def set_load
    @model = Load.find(load_id)
  end

  def mark_as_landed
    @model.assign_attributes(state: :landed, is_open: false)
  end

  def finalize_orders
    @model.slots.each do |slot|
      compose(
        ::Transactions::Confirm,
        receipt: slot.order.receipts.first
      )
    end
  end
end
