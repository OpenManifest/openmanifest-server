# frozen_string_literal: true

class Demo::Generators::Loads < ApplicationInteraction
  date_time :start_date, default: -> { 3.months.ago.to_datetime }

  steps :create_loads
  success do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      resource: access_context.dropzone,
      action: :created,
      access_level: :system,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "[Demo] Created #{@load_count} loads with #{@slot_count} slots spread over #{days_with_loads} days"
    )
  end

  def days_with_loads
    days_since_start = DateTime.now.mjd - start_date.mjd

    # Create loads on random
    @days_with_loads ||= Random.rand((days_since_start / 4)..(days_since_start / 2))
  end

  def dates_with_loads
    used_dates = []
    while used_dates.size < days_with_loads
      random_date = Faker::Date.between(from: start_date.to_date, to: Date.today)
      used_dates << random_date unless used_dates.include?(random_date)
    end
    @dates_with_loads ||= used_dates
  end

  def create_loads
    dates_with_loads.each do |date|
      # Create between 1 and 8 loads for each day
      loads_per_day = Random.rand(1..8)
      (0..loads_per_day).to_a.map do |i|
        create_past_load(date.to_datetime + i.hours)
      end
    end
  end

  def create_past_load(date)
    @load_count ||= 0
    @slot_count ||= 0
    return if access_context.dropzone.loads.exists?(created_at: date)
    # Create a caravan load
    plane_load = compose(
      ::Manifest::CreateLoad,
      access_context: access_context,
      created_at: date,
      pilot: access_context.dropzone.dropzone_users.with_acting_permission(:actAsPilot).shuffle.first,
      gca: access_context.dropzone.dropzone_users.with_acting_permission(:actAsGCA).shuffle.first,
      plane: access_context.dropzone.planes.to_a.sample
    )
    @load_count += 1

    # Manifest user groups
    taken_slots = 0
    while taken_slots < plane_load.max_slots
      group_size = Random.rand(4) + 1
      taken_slots += group_size
      break if taken_slots > plane_load.max_slots
      dz_users = access_context.dropzone.dropzone_users.where.not(id: plane_load.slots.pluck(:dropzone_user_id)).take(group_size)
      jump_type = JumpType.allowed_for(dz_users).sample
      ticket_type = access_context.dropzone.ticket_types.find_by(name: "Height")
      group_leader = dz_users.first
      group_leader.grant! :createUserSlotWithSelf

      compose(
        ::Manifest::CreateMultipleSlots,
        access_context: ::ApplicationInteraction::AccessContext.new(group_leader),
        ticket_type: ticket_type,
        jump_type: jump_type,
        load: plane_load,
        created_at: date,
        users: dz_users.map do |u|
          { dropzone_user: u, exit_weight: u.exit_weight, rig: u.rigs.sample }
        end
      )
      @slot_count += group_size
    end

    # Dispatch load
    compose(::Manifest::UpdateLoad, access_context: access_context, load: plane_load, dispatch_at: date + 20.minutes)

    compose(::Manifest::FinalizeLoad, load: plane_load, access_context: access_context)
  end
end
