# frozen_string_literal: true

class Federations::AssignUser < ApplicationInteraction
  record :federation
  record :license, default: nil
  record :user
  string :uid, default: nil
  validates :federation, :user, presence: true

  steps :assign_user_to_federation,
        :assign_user_federation_uid,
        :manually_assign_license,
        :save!

  success do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      resource: access_context.dropzone,
      action: :assigned,
      access_level: :admin,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "#{user.name} joined federation #{federation.name} with License #{license.name} (#{uid || 'No license number'})",
    )
  end

  def save!
    errors.merge!(@user_federation.errors) unless @user_federation.save
    @user_federation
  end

  def manually_assign_license
    return unless license
    @user_federation.assign_attributes(
      license: license
    )
  end

  def assign_user_to_federation
    @user_federation = UserFederation.find_or_initialize_by(
      federation: federation,
      user: user
    )
  end

  def assign_user_federation_uid
    return if uid.nil?
    @user_federation.assign_attributes(
      uid: uid
    )
    errors.merge!(@user_federation.errors) unless @user_federation.save
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
