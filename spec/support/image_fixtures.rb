# frozen_string_literal: true

# Images as the app sends them: base64 data URLs
module ImageFixtures
  CONTENT_TYPES = { "png" => "image/png", "jpg" => "image/jpeg", "webp" => "image/webp", "gif" => "image/gif" }.freeze

  def image_data_url(extension = "png", claimed_type: nil)
    bytes = Rails.root.join("spec/fixtures/files/pixel.#{extension}").binread
    "data:#{claimed_type || CONTENT_TYPES.fetch(extension)};base64,#{Base64.strict_encode64(bytes)}"
  end

  def data_url_of(bytes, type = "image/png")
    "data:#{type};base64,#{Base64.strict_encode64(bytes)}"
  end
end

RSpec.configure { |config| config.include ImageFixtures }
