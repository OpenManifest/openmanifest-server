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
  integer :user_role_id, default: nil
  decimal :exit_weight, default: nil
  record :license, default: nil
  datetime :expires_at, default: nil

  steps :authorize,
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
        user_role_id: user_role_id,
        expires_at: expires_at,
      }.compact
    )
    errors.merge!(dropzone_user.user.errors) unless dropzone_user.user.save
    if image
      dropzone_user.user.avatar.attach(data: image)
      # Resize image
      dropzone_user.user.avatar.variant(resize_to_fill: [500, 500], gravity: 'north')
    end
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

  def authorize
    user_dropzone_ids = dropzone_user.user.dropzone_users.pluck(:dropzone_id)
    if user_role_id && user_role_id != dropzone_user.user_role_id && !access_context.subject.can?(:grantPermission)
      errors.add(:base, 'You are not authorized to change user roles')
      return false
    end

    # Users can always update their own profile
    if access_context.user.id == dropzone_user.user.id
      true
    # We can't check for dropzones since User isn't directly
    # linked to any dropzone, but if this user only belongs to
    # one dropzone, and you have access to :updateUser at that dropzone,
    # then you can update the users profile. As soon as the user
    # joins other dropzones, you can no longer edit their profile
    elsif user_dropzone_ids.count == 1 && access_context.can?(:updateUser, dropzone_id: user_dropzone_ids.first)
      true
    elsif user_dropzone_ids.count > 1 && access_context.can?(:updateUser, dropzone_id: user_dropzone_ids.first)
      errors.add(:base, "Update failed. User is a member of multiple dropzones")
    else
      errors.add(:base, "You cant update other users")
    end
  end
end
