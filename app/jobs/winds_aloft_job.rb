# frozen_string_literal: true

class WindsAloftJob < ApplicationJob
  queue_as :default

  # TODO: fetch the winds aloft for the dropzone
  def perform(dropzone); end
end
