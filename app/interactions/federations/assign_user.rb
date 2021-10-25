# frozen_string_literal: true

require "active_interaction"

class Federations::AssignUser < ActiveInteraction::Base
  record :federation
  record :user
  string :uid, default: nil
  integer :license_id, default: nil
  validates :federation, :user, presence: true

  def execute
    assign_user_to_federation
    assign_user_federation_uid unless uid.nil?
    manually_assign_license if !license_id.nil?
    synchronize_qualifications
    errors.merge!(@user_federation.errors) unless @user_federation.save
    @user_federation
  end

  def manually_assign_license
    @user_federation.assign_attributes(
      license: License.find_by(id: license_id)
    )
  end

  def assign_user_to_federation
    @user_federation = UserFederation.find_or_initialize_by(
      federation: federation,
      user: user
    )
  end

  def assign_user_federation_uid
    @user_federation.assign_attributes(
      uid: uid
    )
    errors.merge!(@user_federation.errors) unless @user_federation.save
  end

  def synchronize_qualifications
    case federation.slug
    when 'apf'
      compose(
        Federations::ApfSync,
        user_federation: @user_federation,
      )
    end
  end
end
