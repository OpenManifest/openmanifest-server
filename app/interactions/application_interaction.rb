# frozen_string_literal: true

require "active_interaction"

class ApplicationInteraction < ActiveInteraction::Base
  include ActiveInteraction::Extras::Transaction
  include ApplicationInteraction::Access
  include ApplicationInteraction::Execution
  include ApplicationInteraction::AuditLog
  run_in_transaction!
end
