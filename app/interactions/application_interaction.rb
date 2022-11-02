# frozen_string_literal: true

require "active_interaction"

class ApplicationInteraction < ActiveInteraction::Base
  include ActiveInteraction::Extras::All
  include ApplicationInteraction::Access
  include ApplicationInteraction::Execution
  include ApplicationInteraction::AuditLog
  include ApplicationInteraction::Analytics::AppSignal
  run_in_transaction!
end
