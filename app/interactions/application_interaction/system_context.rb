# frozen_string_literal: true

# The context of work the system does by itself (scheduled jobs): no member acts, it may do everything, and it is named
# "System" in the audit log.
class ApplicationInteraction::SystemContext < ApplicationInteraction::AccessContext
  SYSTEM_USER = Struct.new(:id, :name).new(nil, "System").freeze

  def initialize(dropzone = nil)
    super(nil, dropzone: dropzone)
  end

  def user
    SYSTEM_USER
  end

  def can?(*)
    true
  end
end
