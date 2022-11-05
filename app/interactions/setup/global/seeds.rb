# frozen_string_literal: true

class Setup::Global::Seeds < ApplicationInteraction
  steps :create_jump_types,
        :create_federations,
        :create_permissions

  def create_jump_types
    compose JumpTypes
  end

  def create_federations
    compose Federations
  end

  def create_permissions
    compose Permissions
  end
end
