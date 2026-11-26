# frozen_string_literal: true

class Setup::Global::Seeds::ActivityTypes < ApplicationInteraction
  steps :create_activity_types

  def create_activity_types
    ::ActivityType.import!(
      ::ActivityType.config,
      on_duplicate_key_ignore: true
    )
  end
end
