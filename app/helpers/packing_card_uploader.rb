# frozen_string_literal: true

class PackingCardUploader < CarrierWave::Uploader::Base
  include Cloudinary::CarrierWave

  process convert: "png"
  process tags: ["packing_card"]

  version :thumbnail do
    resize_to_fit(150, 150)
  end


  def store_dir
    "packing_cards/"
  end
end
