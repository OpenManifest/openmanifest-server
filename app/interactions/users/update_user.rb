# frozen_string_literal: true

class Users::UpdateUser < ApplicationInteraction
  record :dropzone_user
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
        :dropzone_user

  def assign_attributes
    dropzone_user.user.assign_attributes(
      {
        name: name,
        nickname: nickname,
        push_token: push_token,
        phone: phone,
        email: email,
        exit_weight: exit_weight,
      }.compact
    )
    save_user
    if image
      dropzone_user.user.avatar.attach(data: image)
      # Resize image
      dropzone_user.user.avatar.variant(resize_to_fill: [500, 500], gravity: 'north')
    end
  end

  # Taking somebody else's email is a validation error, not a database exception (BUG-094)
  def check_email
    return if email.blank?
    return unless User.where.not(id: dropzone_user.user_id).exists?(["LOWER(email) = ? OR LOWER(uid) = ?", email.downcase, email.downcase])

    errors.add(:email, "has already been taken")
  end

  def save_user
    user = dropzone_user.user
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
      user: dropzone_user.user,
      license: license,
      uid: federation_number,
      federation: license.federation,
      access_context: access_context
    )
  end

  # Users can always update their own profile. A profile belongs to the user, not to a dropzone, so staff may edit it
  # only while the user is a member of no other dropzone than the one the staff member acts in (updateUser there).
  def authorize
    return if access_context.user&.id == dropzone_user.user_id

    dropzone_ids = dropzone_user.user.dropzone_users.kept.pluck(:dropzone_id)
    if !access_context.can?(:updateUser) || dropzone_user.dropzone_id != access_context.dropzone&.id
      errors.add(:base, "You cant update other users")
    elsif dropzone_ids.uniq.size > 1
      errors.add(:base, "Update failed. User is a member of multiple dropzones")
    end
  end
end
