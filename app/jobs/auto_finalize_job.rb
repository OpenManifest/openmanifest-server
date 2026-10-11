# frozen_string_literal: true

# Lands or cancels the loads of past days, every 15 minutes (config/recurring.yml)
class AutoFinalizeJob < ApplicationJob
  queue_as :default

  def perform
    Manifest::Schedule::AutoFinalize.run!
  end
end
