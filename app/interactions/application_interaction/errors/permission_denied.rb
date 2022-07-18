# frozen_string_literal: true

class ApplicationInteraction::Errors::PermissionDenied < StandardError
  def initialize(message = nil)
    super(message)
  end
end
