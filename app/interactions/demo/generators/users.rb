# frozen_string_literal: true

class Demo::Generators::Users < ApplicationInteraction
  integer :gca_count, default: 3
  integer :duty_officer_count, default: 3
  integer :jumper_count, default: 20
  integer :pilot_count, default: 2
  integer :tandem_instructor_count, default: 3
  integer :aff_instructor_count, default: 3
  integer :equipment_inspector_count, default: 2
  integer :coach_count, default: 3
  steps :import_users!,
        :assign_duty_officer,
        :assign_gca,
        :assign_equipment_inspectors,
        :assign_certification_levels,
        :add_credits!

  success do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      resource: access_context.operator,
      action: :created,
      access_level: :system,
      operator: access_context.operator,
      created_by: access_context.subject,
      message: "[Demo] Created 1 CI, #{gca_count} GCAs, #{aff_instructor_count} AFF instructors, #{tandem_instructor_count} Tandem Instructors, #{pilot_count} pilots, #{coach_count} coaches and #{jumper_count} fun jumpers"
    )
  end

  def users
    @users ||= User.create_fake(
      count: [
        1, # CI
        tandem_instructor_count,
        aff_instructor_count,
        coach_count,
        pilot_count,
        jumper_count,
      ].sum
    )
  end

  def build_ci
    {
      user_id: users.pop.id,
      operator_id: access_context.operator.id,
      user_role_id: access_context.operator.user_roles.find_by(name: :chief_instructor).id,
    }
  end

  def build_tandem_instructors
    (0...tandem_instructor_count).to_a.map do
      {
        user_id: users.pop.id,
        operator_id: access_context.operator.id,
        user_role_id: access_context.operator.user_roles.find_by(name: :tandem_instructor).id,
      }
    end
  end

  # Create coaches
  def build_coaches
    (0...coach_count).to_a.map do
      {
        user_id: users.pop.id,
        operator_id: access_context.operator.id,
        user_role_id: access_context.operator.user_roles.find_by(name: :coach).id,
      }
    end
  end

  # Create AFF instructors
  def build_aff_instructors
    (0...aff_instructor_count).to_a.map do
      {
        user_id: users.pop.id,
        operator_id: access_context.operator.id,
        user_role_id: access_context.operator.user_roles.find_by(name: :aff_instructor).id,
      }
    end
  end

  # Create pilots
  def build_pilots
    (0...pilot_count).to_a.map do
      {
        user_id: users.pop.id,
        operator_id: access_context.operator.id,
        user_role_id: access_context.operator.user_roles.find_by(name: :pilot).id,
      }
    end
  end

  # Create jumpers
  def build_jumpers
    (0...jumper_count).to_a.map do
      {
        user_id: users.pop.id,
        operator_id: access_context.operator.id,
        user_role_id: access_context.operator.user_roles.find_by(name: :fun_jumper).id,
      }
    end
  end

  def import_users!
    importable = [
      build_ci,
      build_tandem_instructors,
      build_aff_instructors,
      build_coaches,
      build_pilots,
      build_jumpers,
    ].flatten.map do |importable|
      importable.merge(created_at: DateTime.now, updated_at: DateTime.now)
    end
    Membership.insert_all(importable)
  end

  def add_credits!
    access_context.operator.memberships.each do |dz_user|
      compose(
        ::Transactions::CreateOrder,
        title: "Add demo credits",
        amount: Random.rand(4000..8000),
        buyer: access_context.operator,
        seller: dz_user,
        operator: access_context.operator,
        access_context: ::ApplicationInteraction::AccessContext.new(dz_user)
      )
    end
  end

  def assign_duty_officer
    @duty_officer = access_context.operator.memberships.staff.shuffle.take(duty_officer_count).each do |dz_user|
      dz_user.grant! :actAsDutyOfficer
      dz_user
    end
  end

  def assign_gca
    @gca = access_context.operator.memberships.staff.shuffle.take(gca_count).map do |dz_user|
      dz_user.grant! :actAsGCA
      dz_user
    end
  end

  def assign_pilots
    @gca = access_context.operator.memberships.includes(:user_role).where(user_role: { name: :pilot }).map do |dz_user|
      dz_user.grant! :actAsPilot
      dz_user
    end
  end

  def assign_equipment_inspectors
    @equipment_inspectors = access_context.operator.memberships.staff.shuffle.take(equipment_inspector_count).map do |dz_user|
      dz_user.grant! :actAsEquipmentInspector
      dz_user
    end
  end

  def assign_certification_levels
    access_context.operator.memberships.includes(:certification_level).where(certification_level: { id: nil }).each do |dz_user|
      certification_level_options = access_context.operator.certification_bodies.first.certification_levels.reorder(rank: :desc)
      certification_level_options = certification_level_options.limit(3).to_a.sample if %i(
        chief_instructor tandem_instructor aff_instructor
        coach
      ).include?(dz_user.user_role.name)
      certification_level_options = certification_level_options.to_a.sample unless %i(
        chief_instructor tandem_instructor aff_instructor
        coach
      ).include?(dz_user.user_role.name)
      compose(
        ::Certifications::AssignUser,
        access_context: ::ApplicationInteraction::AccessContext.new(dz_user),
        certification_body: access_context.operator.certification_bodies.first,
        certification_level: certification_level_options,
        uid: Random.rand(10000..16000).to_s,
        user: dz_user.user
      )
    end
  end
end
