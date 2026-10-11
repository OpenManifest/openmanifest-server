# frozen_string_literal: true

module ApplicationCable
  # A cable connection belongs to a user. Browsers cannot set headers on a WebSocket, so the devise token credentials
  # (`access-token`, `client`, `uid`) are query parameters of the cable URL. Anyone else is rejected.
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user || reject_unauthorized_connection
    end

    private

    def find_verified_user
      token = request.params["access-token"]
      client = request.params["client"]
      uid = request.params["uid"]
      return nil if token.blank? || client.blank? || uid.blank?

      # The uid is the email for email accounts and the provider's id for Apple and Facebook ones (BUG-060). Several
      # accounts could share one uid across providers, so take the one the token belongs to.
      User.where(uid: uid).find { |user| user.valid_token?(token, client) }
    end
  end
end
