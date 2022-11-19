# frozen_string_literal: true

class Setup::Users::CreateGhost < ApplicationInteraction
  string :name
  string :email
  decimal :exit_weight
  record :dropzone
  record :role, class: ::UserRole

  string :phone, default: nil
  string :federation_number, default: nil
  record :license, default: nil

  allow :createUser
  steps :check_user_exists,
        :initialize_user,
        :create_dropzone_user,
        :invite,
        :assign_federation,
        :record

  success do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      resource: @user,
      action: :created,
      access_level: :admin,
      dropzone: access_context.dropzone,
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
      dropzone: access_context.dropzone,
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
      exit_weight: exit_weight,
      email: email,
      password: SecureRandom.urlsafe_base64(9)
    )

    errors.merge!(@user.errors) unless @user.save
  end

  def create_dropzone_user
    return unless dropzone
    dropzone.dropzone_users.create(
      user_role: role,
      user: @user
    )
  end

  def invite
    @user&.send_confirmation_instructions
  end

  def assign_federation
    return unless license
    federation = Federation.includes(:licenses).find_by(licenses: { id: license.id })
    return unless federation
    compose(
      Federations::AssignUser,
      user: @user,
      uid: federation_number,
      license: license,
      federation: federation,
      access_context: access_context
    )
  end

  def record
    @user
  end
end
