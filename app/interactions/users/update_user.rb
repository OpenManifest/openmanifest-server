# frozen_string_literal: true

class Users::UpdateUser < ApplicationInteraction
  # The member whose profile is edited; without one the caller edits their own profile (logging out clears the push token
  # before any operator is chosen)
  record :membership, default: nil
  record :user, default: nil
  string :name, default: nil
  string :nickname, default: nil
  string :push_token, default: nil
  string :image, default: nil
  string :certification_body_number, default: nil
  string :phone, default: nil
  string :email, default: nil
  decimal :body_mass_kg, default: nil
  date :date_of_birth, default: nil
  record :certification_level, default: nil

  steps :authorize,
        :check_email,
        :assign_attributes,
        :assign_certification_body,
        :result

  def assign_attributes
    attributes = {
      name: name,
      nickname: nickname,
      phone: phone,
      email: email,
      body_mass_kg: body_mass_kg,
      date_of_birth: date_of_birth,
    }.compact
    # Sending null clears the push token (logging out); leaving it out keeps it
    attributes[:push_token] = push_token if inputs.given?(:push_token)
    target_user.assign_attributes(attributes)
    save_user
    attach_avatar if image
  end

  def result
    membership
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

  def assign_certification_body
    return unless certification_level
    # Joining the body of the chosen level updates the level of every membership
    # at an operator that accepts that body:
    compose(
      Certifications::AssignUser,
      user: target_user,
      certification_level: certification_level,
      uid: certification_body_number,
      certification_body: certification_level.certification_body,
      access_context: access_context
    )
  end

  # Users can always update their own profile. A profile belongs to the user, not to an operator, so staff may edit it
  # only while the user is a member of no other operator than the one the staff member acts in (updateUser there).
  def authorize
    return errors.add(:base, "Nobody to update") unless target_user
    return if access_context.user&.id == target_user.id
    return errors.add(:base, "You cant update other users") unless membership

    operator_ids = target_user.memberships.kept.pluck(:operator_id)
    if !access_context.can?(:updateUser) || membership.operator_id != access_context.operator&.id
      errors.add(:base, "You cant update other users")
    elsif operator_ids.uniq.size > 1
      errors.add(:base, "Update failed. User is a member of multiple operators")
    end
  end

  private

  def target_user
    membership&.user || user
  end
end
