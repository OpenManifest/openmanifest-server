# frozen_string_literal: true

# Fills a weather condition with the winds of its operator's location (an external service, 5 second timeout)
class FetchWindsJob < ApplicationJob
  queue_as :default

  # What can go wrong reaching the service
  NETWORK_ERRORS = [Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNRESET, Errno::ECONNREFUSED, HTTParty::Error].freeze

  retry_on(*NETWORK_ERRORS, wait: :polynomially_longer, attempts: 5)
  discard_on ActiveRecord::RecordNotFound

  def perform(weather_condition_id)
    condition = WeatherCondition.find(weather_condition_id)
    operator = condition.operator
    return unless operator.lat.present? && operator.lng.present?

    condition.from_coordinates(operator.lat, operator.lng)
    condition.save!
  end
end
