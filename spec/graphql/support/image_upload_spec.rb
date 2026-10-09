# frozen_string_literal: true

require "rails_helper"

RSpec.describe Support::ImageUpload do
  describe ".attachable" do
    %w(png jpg webp).each do |extension|
      it "accepts a #{extension.upcase}" do
        attachable = described_class.attachable(image_data_url(extension), name: "banner")

        expect(attachable).to include(content_type: ImageFixtures::CONTENT_TYPES.fetch(extension), filename: "banner.#{extension}")
        expect(attachable[:io].read).to eq(Rails.root.join("spec/fixtures/files/pixel.#{extension}").binread)
      end
    end

    it "reads the type from the bytes, not from what the client says" do
      attachable = described_class.attachable(image_data_url("jpg", claimed_type: "image/png"), name: "card")

      expect(attachable).to include(content_type: "image/jpeg", filename: "card.jpg")
    end

    it "refuses a GIF" do
      expect { described_class.attachable(image_data_url("gif"), name: "banner") }.to raise_error(described_class::Invalid, /PNG, JPEG or WebP/)
    end

    it "refuses a script that says it is a PNG" do
      expect { described_class.attachable(data_url_of("<script>alert(1)</script>"), name: "banner") }.to raise_error(described_class::Invalid, /PNG, JPEG or WebP/)
    end

    it "refuses an SVG" do
      svg = '<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script></svg>'

      expect { described_class.attachable(data_url_of(svg, "image/svg+xml"), name: "banner") }.to raise_error(described_class::Invalid)
    end

    it "refuses an image of more than 5 MB" do
      big = Rails.root.join("spec/fixtures/files/pixel.png").binread + ("\0" * (5 * 1024 * 1024))

      expect { described_class.attachable(data_url_of(big), name: "banner") }.to raise_error(described_class::Invalid, /too large/)
    end

    it "refuses a string that is not a data URL" do
      expect { described_class.attachable(Base64.strict_encode64("x"), name: "banner") }.to raise_error(described_class::Invalid, /data URL/)
    end

    it "refuses data that is not base64" do
      expect { described_class.attachable("data:image/png;base64,@@@", name: "banner") }.to raise_error(described_class::Invalid, /could not be read/)
    end

    it "refuses nothing" do
      expect { described_class.attachable(nil, name: "banner") }.to raise_error(described_class::Invalid)
    end
  end
end
