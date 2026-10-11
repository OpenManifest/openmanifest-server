# frozen_string_literal: true

class Users::UpdateUser < ApplicationInteraction
  # The member whose profile is edited; without one the caller edits their own profile (logging out clears the push token
  # before any dropzone is chosen)
  record :dropzone_user, default: nil
  record :user, default: nil
  string :name, default: nil
  string :nickname, default: nil
  string :push_token, default: nil
  string :image, default: nil
  string :federation_number, default: nil
  string :phone, default: nil
  string :email, default: nil
  decimal :exit_weight, default: nil
  record :license, default: nil

  steps :authorize,
        :check_email,
        :assign_attributes,
        :assign_federation,
        :result

  def assign_attributes
    attributes = {
      name: name,
      nickname: nickname,
      phone: phone,
      email: email,
      exit_weight: exit_weight,
    }.compact
    # Sending null clears the push token (logging out); leaving it out keeps it
    attributes[:push_token] = push_token if inputs.given?(:push_token)
    target_user.assign_attributes(attributes)
    save_user
    attach_avatar if image
  end

  def result
    dropzone_user
  end

  def attach_avatar
    Support::ImageUpload.attach(target_user.avatar, image, name: "avatar")
  rescue Support::ImageUpload::Invalid => e
    errors.add(:image, e.message)
  end

  # Taking somebody else's email is a validation error, not a database exception (BUG-094)
  def check_email
    return if email.blank?
    return unless User.where.not(id: target_user.id).exists?(["LOWER(email) = ? OR LOWER(uid) = ?", email.downcase, email.downcase])

    errors.add(:email, "has already been taken")
  end

  def save_user
    user = target_user
    # The savepoint keeps the transaction usable if a concurrent request took the email in the meantime
    saved = User.transaction(requires_new: true) { user.save }
    errors.merge!(user.errors) unless saved
  rescue ActiveRecord::RecordNotUnique
    errors.add(:email, "has already been taken")
  end

  def assign_federation
    return unless license
    # If license id changed, then update all DropzoneUsers
    # with the same federation as that license to have the
    # new license:
    compose(
      Federations::AssignUser,
      user: target_user,
      license: license,
      uid: federation_number,
      federation: license.federation,
      access_context: access_context
    )
  end

  # Users can always update their own profile. A profile belongs to the user, not to a dropzone, so staff may edit it
  # only while the user is a member of no other dropzone than the one the staff member acts in (updateUser there).
  def authorize
    return errors.add(:base, "Nobody to update") unless target_user
    return if access_context.user&.id == target_user.id
    return errors.add(:base, "You cant update other users") unless dropzone_user

    dropzone_ids = target_user.dropzone_users.kept.pluck(:dropzone_id)
    if !access_context.can?(:updateUser) || dropzone_user.dropzone_id != access_context.dropzone&.id
      errors.add(:base, "You cant update other users")
    elsif dropzone_ids.uniq.size > 1
      errors.add(:base, "Update failed. User is a member of multiple dropzones")
    end
  end

  private

  def target_user
    dropzone_user&.user || user
  end
end
