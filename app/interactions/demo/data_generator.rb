# frozen_string_literal: true

class Demo::DataGenerator < ApplicationInteraction
  record :operator, default: nil
  string :industry, default: "skydiving"
  date_time :start_date, default: -> { 3.months.ago.to_datetime }

  import_filters Demo::Generators::Users

  steps :create_tickets,
        :create_vehicles,
        :create_users,
        :create_loads

  def check_eligibility
    errors.add(:base, "You cannot add demo data to a live operator") if operator.state == "public"
  end

  def dz
    @dz ||= operator || compose(
      ::Setup::Operators::CreateOperator,
      owner: User.create_fake,
      industry: industry,
      time_zone: "Australia/Brisbane",
      name: "Skydive #{Faker::Address.city}",
      lat: Faker::Address.latitude,
      lng: Faker::Address.longitude,
      primary_color: Faker::Color.hex_color,
      secondary_color: Faker::Color.hex_color,
      is_credit_system_enabled: true,
      federation: Federation.first,
    )
  end

  def operator_owner
    @operator_owner ||= dz.memberships.reload.includes(:user_role).find_by(user_roles: { name: :owner })
  end

  def owner_access_context
    ::ApplicationInteraction::AccessContext.new(operator_owner)
  end

  def create_tickets
    return nil if operator.ticket_types.any?
    compose(
      ::Demo::Generators::Tickets,
      access_context: owner_access_context
    )
  end

  def create_vehicles
    return nil if operator.vehicles.any?
    compose(
      ::Demo::Generators::Vehicles,
      access_context: owner_access_context
    )
  end

  def create_users
    return if owner_access_context.operator.memberships.count > 20
    compose(
      ::Demo::Generators::Users,
      gca_count: gca_count,
      duty_officer_count: duty_officer_count,
      jumper_count: jumper_count,
      tandem_instructor_count: tandem_instructor_count,
      aff_instructor_count: aff_instructor_count,
      coach_count: coach_count,
      pilot_count: pilot_count,
      access_context: owner_access_context
    )
  end

  def create_loads
    compose(
      ::Demo::Generators::Loads,
      start_date: start_date,
      access_context: owner_access_context
    )
  end
end
