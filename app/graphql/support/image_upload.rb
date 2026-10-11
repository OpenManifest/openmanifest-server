# frozen_string_literal: true

# Turns the image the app sends (a base64 data URL, as the image picker produces it) into something ActiveStorage can
# attach, after checking what it really is: a PNG, JPEG or WebP of at most 5 MB. The content type is read from the bytes,
# not taken from what the client says.
module Support
  module ImageUpload
    CONTENT_TYPES = %w(image/png image/jpeg image/webp).freeze
    EXTENSIONS = { "image/png" => "png", "image/jpeg" => "jpg", "image/webp" => "webp" }.freeze
    MAX_BYTES = 5 * 1024 * 1024
    DATA_URL = %r{\Adata:image/[a-z0-9.+-]+;base64,(?<data>.+)\z}mi

    class Invalid < StandardError; end

    # @param data_url [String] e.g. "data:image/jpeg;base64,/9j/4AAQ..."
    # @param name [String] the base of the file name, e.g. "banner"
    # @return [Hash] io:, filename:, content_type: for `attachment.attach`
    def self.attachable(data_url, name:)
      match = DATA_URL.match(data_url.to_s)
      raise Invalid, "The image must be a data URL (data:image/jpeg;base64,...)" unless match

      encoded = match[:data]
      raise Invalid, "The image is too large (at most #{MAX_BYTES / 1.megabyte} MB)" if encoded.bytesize > (MAX_BYTES * 4 / 3) + 4

      bytes = begin
        Base64.strict_decode64(encoded.delete("\r\n"))
      rescue ArgumentError
        raise Invalid, "The image could not be read"
      end
      raise Invalid, "The image is too large (at most #{MAX_BYTES / 1.megabyte} MB)" if bytes.bytesize > MAX_BYTES

      content_type = Marcel::MimeType.for(StringIO.new(bytes))
      raise Invalid, "The image must be a PNG, JPEG or WebP" unless CONTENT_TYPES.include?(content_type)

      { io: StringIO.new(bytes), filename: "#{name}.#{EXTENSIONS.fetch(content_type)}", content_type: content_type, identify: false }
    end

    # Attaches the image to an attachment of a record, e.g. `attach(dropzone.banner, data_url, name: "banner")`
    def self.attach(attachment, data_url, name:)
      attachment.attach(**attachable(data_url, name: name))
    end
  end
end
