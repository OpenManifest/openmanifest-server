# frozen_string_literal: true

class Setup::Global::Seeds::JumpTypes < ApplicationInteraction
  steps :create_jump_types

  def create_jump_types
    ::JumpType.import!(
      ::JumpType.config,
      on_duplicate_key_ignore: true
    )
  end
end
