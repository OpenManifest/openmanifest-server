# frozen_string_literal: true

class Setup::Global::Seeds < ApplicationInteraction
  steps :create_activity_types,
        :create_federations,
        :create_permissions

  def create_activity_types
    compose ActivityTypes
  end

  def create_federations
    compose Federations
  end

  def create_permissions
    compose Permissions
  end
end
