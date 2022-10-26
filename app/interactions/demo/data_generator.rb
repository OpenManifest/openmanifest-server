# frozen_string_literal: true

class Demo::DataGenerator < ApplicationInteraction
  record :dropzone, default: nil
  date_time :start_date, default: -> { 3.months.ago.to_datetime }

  import_filters Demo::Generators::Users

  steps :create_tickets,
        :create_aircrafts,
        :create_users,
        :create_loads

  def dz
    @dz ||= dropzone || compose(
      ::Setup::Dropzones::CreateDropzone,
      owner: User.create_fake,
      name: "Skydive #{Faker::Address.city}",
      lat: Faker::Address.latitude,
      lng: Faker::Address.longitude,
      primary_color: Faker::Color.hex_color,
      secondary_color: Faker::Color.hex_color,
      is_credit_system_enabled: true,
      federation: Federation.first,
    )
  end

  def dropzone_owner
    @dropzone_owner ||= dz.dropzone_users.reload.includes(:user_role).find_by(user_roles: { name: :owner })
  end

  def owner_access_context
    ::ApplicationInteraction::AccessContext.new(dropzone_owner)
  end

  def create_tickets
    compose(
      ::Demo::Generators::Tickets,
      access_context: owner_access_context
    )
  end

  def create_aircrafts
    compose(
      ::Demo::Generators::Aircrafts,
      access_context: owner_access_context
    )
  end

  def create_users
    return if owner_access_context.dropzone.dropzone_users.count > 20
    compose(
      ::Demo::Generators::Users,
      gca_count: gca_count,
      dzso_count: dzso_count,
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
