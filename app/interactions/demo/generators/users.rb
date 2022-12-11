# frozen_string_literal: true

class Demo::Generators::Users < ApplicationInteraction
  integer :gca_count, default: 3
  integer :dzso_count, default: 3
  integer :jumper_count, default: 20
  integer :pilot_count, default: 2
  integer :tandem_instructor_count, default: 3
  integer :aff_instructor_count, default: 3
  integer :rig_inspector_count, default: 2
  integer :coach_count, default: 3
  steps :import_users!,
        :assign_dzso,
        :assign_gca,
        :assign_rig_inspectors,
        :assign_licenses,
        :add_credits!

  success do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      resource: access_context.dropzone,
      action: :created,
      access_level: :system,
      dropzone: access_context.dropzone,
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
      dropzone_id: access_context.dropzone.id,
      user_role_id: access_context.dropzone.user_roles.find_by(name: :chief_instructor).id,
    }
  end

  def build_tandem_instructors
    (0...tandem_instructor_count).to_a.map do
      {
        user_id: users.pop.id,
        dropzone_id: access_context.dropzone.id,
        user_role_id: access_context.dropzone.user_roles.find_by(name: :tandem_instructor).id,
      }
    end
  end

  # Create coaches
  def build_coaches
    (0...coach_count).to_a.map do
      {
        user_id: users.pop.id,
        dropzone_id: access_context.dropzone.id,
        user_role_id: access_context.dropzone.user_roles.find_by(name: :coach).id,
      }
    end
  end

  # Create AFF instructors
  def build_aff_instructors
    (0...aff_instructor_count).to_a.map do
      {
        user_id: users.pop.id,
        dropzone_id: access_context.dropzone.id,
        user_role_id: access_context.dropzone.user_roles.find_by(name: :aff_instructor).id,
      }
    end
  end

  # Create pilots
  def build_pilots
    (0...pilot_count).to_a.map do
      {
        user_id: users.pop.id,
        dropzone_id: access_context.dropzone.id,
        user_role_id: access_context.dropzone.user_roles.find_by(name: :pilot).id,
      }
    end
  end

  # Create jumpers
  def build_jumpers
    (0...jumper_count).to_a.map do
      {
        user_id: users.pop.id,
        dropzone_id: access_context.dropzone.id,
        user_role_id: access_context.dropzone.user_roles.find_by(name: :fun_jumper).id,
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
    DropzoneUser.insert_all(importable)
  end

  def add_credits!
    access_context.dropzone.dropzone_users.each do |dz_user|
      compose(
        ::Transactions::CreateOrder,
        title: "Add demo credits",
        amount: Random.rand(4000..8000),
        buyer: access_context.dropzone,
        seller: dz_user,
        dropzone: access_context.dropzone,
        access_context: ::ApplicationInteraction::AccessContext.new(dz_user)
      )
    end
  end

  def assign_dzso
    @dzso = access_context.dropzone.dropzone_users.staff.shuffle.take(dzso_count).each do |dz_user|
      dz_user.grant! :actAsDZSO
      dz_user
    end
  end

  def assign_gca
    @gca = access_context.dropzone.dropzone_users.staff.shuffle.take(gca_count).map do |dz_user|
      dz_user.grant! :actAsGCA
      dz_user
    end
  end

  def assign_pilots
    @gca = access_context.dropzone.dropzone_users.includes(:user_role).where(user_role: { name: :pilot }).map do |dz_user|
      dz_user.grant! :actAsPilot
      dz_user
    end
  end

  def assign_rig_inspectors
    @rig_inspectors = access_context.dropzone.dropzone_users.staff.shuffle.take(rig_inspector_count).map do |dz_user|
      dz_user.grant! :actAsRigInspector
      dz_user
    end
  end

  def assign_licenses
    access_context.dropzone.dropzone_users.includes(:license).where(license: { id: nil }).each do |dz_user|
      license_options = access_context.dropzone.federation.licenses.order(id: :desc)
      license_options = license_options.limit(3).to_a.sample if %i(
        chief_instructor tandem_instructor aff_instructor
        coach
      ).include?(dz_user.user_role.name)
      license_options = license_options.to_a.sample unless %i(
        chief_instructor tandem_instructor aff_instructor
        coach
      ).include?(dz_user.user_role.name)
      compose(
        ::Federations::AssignUser,
        access_context: ::ApplicationInteraction::AccessContext.new(dz_user),
        federation: access_context.dropzone.federation,
        license: license_options,
        uid: Random.rand(10000..16000).to_s,
        user: dz_user.user
      )
    end
  end
end
