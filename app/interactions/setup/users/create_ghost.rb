# frozen_string_literal: true

class Setup::Users::CreateGhost < ApplicationInteraction
  string :name
  string :email
  decimal :body_mass_kg
  record :operator
  record :role, class: ::UserRole

  string :phone, default: nil
  string :certification_body_number, default: nil
  record :certification_level, default: nil

  allow :createUser
  steps :check_user_exists,
        :initialize_user,
        :create_membership,
        :invite,
        :assign_certification_body,
        :record

  success do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      resource: @user,
      action: :created,
      access_level: :admin,
      operator: access_context.operator,
      created_by: access_context.subject,
      message: "Created a new user: '#{@user.name}' (#{@user.email})"
    )
  end

  error do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      level: :error,
      resource: @user&.persisted? ? @user : nil,
      action: :created,
      access_level: :admin,
      operator: access_context.operator,
      created_by: access_context.subject,
      message: "Failed creating user: '#{name}' (#{email}) - #{errors.full_messages.join(', ')}"
    )
  end

  def check_user_exists
    return unless User.exists?(email: email) || User.exists?(unconfirmed_email: email)
    errors.add(:base, "User already exists")
  end

  def initialize_user
    @user = User.find_or_initialize_by(
      unconfirmed_email: email,
    )

    @user.assign_attributes(
      name: name,
      phone: phone,
      body_mass_kg: body_mass_kg,
      email: email,
      password: SecureRandom.urlsafe_base64(9)
    )

    errors.merge!(@user.errors) unless @user.save
  end

  def create_membership
    return unless operator
    operator.memberships.create(
      user_role: role,
      user: @user
    )
  end

  def invite
    @user&.send_confirmation_instructions
  end

  def assign_certification_body
    return unless certification_level
    certification_body = CertificationBody.includes(:certification_levels).find_by(certification_levels: { id: certification_level.id })
    return unless certification_body
    compose(
      Certifications::AssignUser,
      user: @user,
      uid: certification_body_number,
      certification_level: certification_level,
      certification_body: certification_body,
      access_context: access_context
    )
  end

  def record
    @user
  end
end
