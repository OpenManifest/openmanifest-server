require "active_interaction"

class Login::Apple < ActiveInteraction::Base
  include ActiveInteraction::Extras::All
  run_in_transaction!
  string :token
  string :authorization_code

  class AuthenticationFailed < StandardError
  end

  def execute
    puts token
    puts authorization_code
    # TODO: Fix verification here
    raise AuthenticationFailed
  rescue
    raise AuthenticationFailed
  end
end
