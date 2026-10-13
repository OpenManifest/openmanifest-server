# frozen_string_literal: true

class Manifest::CreateLoad < ApplicationInteraction
  allow :createLoad

  string  :name,          default: ""
  integer :max_slots,     default: nil
  object  :pilot,         class: Membership, default: nil
  object  :gca,           class: Membership, default: nil
  object  :load_master,   class: Membership, default: nil
  # Either the vehicle, or the vehicles with their roles (operators with several vehicles per load)
  object  :vehicle, class: Vehicle, default: nil
  array   :vehicles, default: nil do
    hash do
      record :vehicle
      string :role, default: "carrying"
    end
  end
  # The crew of the load by role (and by vehicle, for roles per vehicle); `pilot`, `gca` and `load_master` fill the roles of
  # that key
  array :crew, default: nil do
    hash do
      record :crew_role
      record :membership
      record :load_vehicle, default: nil
      record :vehicle, default: nil
    end
  end
  # The places the load visits, in order (operators with per-load destinations)
  array :destination_ids, default: nil do
    integer
  end
  # Ignored: a new load is always open
  string :state, default: "open"
  date_time :created_at, default: -> { DateTime.current }

  validate :vehicle_given

  steps :build_load,
        :save

  # Create events
  success do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      resource: @load,
      action: :created,
      access_level: :user,
      created_at: created_at,
      operator: access_context.operator,
      created_by: access_context.subject,
      message: "#{access_context.user.name} created load ##{@load.load_number}"
    )
  end

  # Create events
  error do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      level: :error,
      action: :created,
      created_at: created_at,
      operator: access_context.operator,
      created_by: access_context.subject,
      message: "#{access_context.user.name} failed to create a new load"
    )
  end

  def build_load
    @load = access_context.operator.loads.new(
      name: name,
      created_at: created_at
    )
    @load.vehicle_roles = vehicles || [{ vehicle: vehicle, role: "carrying" }]
    @load.enforce_crew_permissions = true
    @load.crew_entries = crew.map(&:symbolize_keys) if crew
    @load.gca = gca if gca
    @load.pilot = pilot if pilot
    @load.load_master = load_master if load_master
    @load.max_slots = max_slots || @load.capacity
    @load.destination_ids = destination_ids unless destination_ids.nil?
  end

  def save
    errors.merge!(@load.errors) unless @load.save
    @load
  end

  private

  def vehicle_given
    errors.add(:base, "A load needs a vehicle") if vehicle.nil? && vehicles.blank?
  end
end
