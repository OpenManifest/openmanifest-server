# frozen_string_literal: true

# Browsers may call the API only from the frontends listed in CORS_ORIGINS (comma separated, scheme://host[:port]). The
# native apps send no Origin header and are not affected. The origin of FRONTEND_URL (required in production) is always
# allowed, so a deployment that has it set keeps serving its own web app.
module CorsOrigins
  DEFAULT = "http://localhost:19006,http://localhost:8081"

  def self.list(env = ENV)
    configured = env.fetch("CORS_ORIGINS", DEFAULT).split(",").map(&:strip).reject(&:empty?)
    (configured + [origin_of(env["FRONTEND_URL"])]).compact.uniq
  end

  def self.origin_of(url)
    uri = URI.parse(url.to_s.strip)
    return unless uri.scheme && uri.host

    "#{uri.scheme}://#{uri.host}#{":#{uri.port}" unless uri.port == uri.default_port}"
  rescue URI::InvalidURIError
    nil
  end
end

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*CorsOrigins.list)
    resource "*", headers: :any, methods: [:get, :post, :patch, :put, :options]
  end
end
