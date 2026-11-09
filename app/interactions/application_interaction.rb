# frozen_string_literal: true

require "active_interaction"

class ApplicationInteraction < ActiveInteraction::Base
  include ActiveInteraction::Extras::All
  include ApplicationInteraction::Access
  include ApplicationInteraction::Execution
  include ApplicationInteraction::AuditLog
  include ApplicationInteraction::Analytics::AppSignal

  run_in_transaction!

  private

  # Server copy (activity events, notifications) in the words of the operator the call is for (Operator#translate); a
  # call without an operator gets the generic template's words
  def copy(key, **values)
    (access_context&.operator || Operator.new(industry: "generic")).translate(key, **values)
  end
end
