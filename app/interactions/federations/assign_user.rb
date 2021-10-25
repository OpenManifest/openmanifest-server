# frozen_string_literal: true

require "active_interaction"

class Federations::AssignUser < ActiveInteraction::Base
  record :federation
  record :user
  string :uid, default: nil
  validates :federation, :user, presence: true

  def execute
    assign_user_to_federation
    assign_user_federation_uid unless uid.nil?
    synchronize_qualifications
    @user_federation
  end

  def assign_user_to_federation
    @user_federation = UserFederation.find_or_initialize_by(
      federation: federation,
      user: user
    )
    errors.merge!(@user_federation.errors) unless @user_federation.save
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
