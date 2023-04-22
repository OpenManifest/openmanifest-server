# frozen_string_literal: true

class Federations::AssignUser < ApplicationInteraction
  record :federation
  record :license, default: -> { federation.licenses.first }
  record :user
  string :uid, default: ''
  validates :federation, :user, presence: true

  steps :assign_user_to_federation,
        :assign_user_federation_uid,
        :manually_assign_license,
        :synchronize_qualifications,
        :save!

  success do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      resource: user,
      action: :assigned,
      access_level: :admin,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "#{user&.name || 'Unknown User'} joined federation #{federation&.name || 'Unknown Federation'} with License #{license&.name} (#{uid || 'No license number'})",
    )
  end

  error do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      resource: access_context.dropzone,
      action: :assigned,
      level: :error,
      access_level: :admin,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "#{user&.name || 'Unknown User'} failed to join federation #{federation&.name || 'Unknown Federation'} with License #{license&.name} (#{uid || 'No license number'})",
    )
  end

  def save!
    errors.merge!(@user_federation.errors) unless @user_federation.save
    @user_federation
  end

  def manually_assign_license
    @user_federation.assign_attributes(
      license: license || federation.licenses.first,
      license_number: ''
    )
    errors.merge!(@user_federation.errors) unless @user_federation.save
  end

  def assign_user_to_federation
    @user_federation ||= UserFederation.find_or_initialize_by(
      federation: federation,
      user: user
    )
  end

  def assign_user_federation_uid
    @user_federation.assign_attributes(
      uid: uid || ' '
    )
  end

  def synchronize_qualifications
    case federation.slug
    when "apf"
      compose(
        Federations::ApfSync,
        user_federation: @user_federation,
        access_context: access_context
      )
    end
  end
end
