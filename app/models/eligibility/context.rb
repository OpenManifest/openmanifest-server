# frozen_string_literal: true

module Eligibility
  # What the rules look at: a slot (saved, or built to ask whether it could be), or just a member
  class Context
    attr_reader :slot, :membership, :load

    def initialize(slot)
      @slot = slot
      @membership = slot.membership
      @load = slot.load
    end

    # A member without a slot: only the rules that need no ticket answer
    def self.for_member(membership, load: nil)
      new(Slot.new(membership: membership, load: load)).tap { |context| context.instance_variable_set(:@summary, true) }
    end

    def summary? = @summary == true

    delegate :guest, :ticket_type, :activity_type, :load_vehicle, :group_number, :created_by, to: :slot

    def operator = membership&.operator || load&.operator || slot.load&.operator

    def event = slot.new_record? ? :create : :change

    def create? = event == :create

    def is_guest? = slot.is_guest?

    def extras = slot.extras.to_a

    def equipment = slot.equipment.to_a

    def guest_slots = slot.guest_slots.reject(&:marked_for_destruction?)

    # The seats the slot takes: its own, and its guests'
    def seats = 1 + guest_slots.size

    def user = membership&.user

    # The mass of whoever the slot is for; a member's own, when the slot has none yet
    def body_mass_kg = slot.body_mass_kg || user&.body_mass_kg

    def cost_cents = slot.ticket_type ? slot.cost_cents : nil

    # The day the slot flies, in the operator's time zone
    def date = load&.load_date || operator&.today

    def may_bypass?(permission)
      !!(created_by&.can?(permission) && operator&.allow_manifest_bypass?)
    end
  end
end
