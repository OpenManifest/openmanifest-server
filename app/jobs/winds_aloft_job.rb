# frozen_string_literal: true

class WindsAloftJob < ApplicationJob
  queue_as :default

  def perform(dropzone)
  rescue
    # TODO: Handle these errors
    # Ignore if notification is removed before sending
  end
end
