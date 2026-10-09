# frozen_string_literal: true

# Fills a weather condition with the winds of its dropzone's location (an external service, 5 second timeout)
class FetchWindsJob < ApplicationJob
  queue_as :default

  # What can go wrong reaching the service
  NETWORK_ERRORS = [Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNRESET, Errno::ECONNREFUSED, HTTParty::Error].freeze

  retry_on(*NETWORK_ERRORS, wait: :polynomially_longer, attempts: 5)
  discard_on ActiveRecord::RecordNotFound

  def perform(weather_condition_id)
    condition = WeatherCondition.find(weather_condition_id)
    dropzone = condition.dropzone
    return unless dropzone.lat.present? && dropzone.lng.present?

    condition.from_coordinates(dropzone.lat, dropzone.lng)
    condition.save!
  end
end
