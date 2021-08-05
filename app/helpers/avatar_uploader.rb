# frozen_string_literal: true

class AvatarUploader < CarrierWave::Uploader::Base
  include Cloudinary::CarrierWave

  process convert: "png"
  process tags: ["avatar"]

  version :standard do
    process resize_to_fill: [300, 300, :north]
  end

  version :thumbnail do
    resize_to_fit(150, 150)
  end

  def store_dir
    "avatars/"
  end
end
