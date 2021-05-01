class BannerUploader < CarrierWave::Uploader::Base
  include Cloudinary::CarrierWave

  process :convert => 'png'
  process :tags => ['avatar']

  version :standard do
    process :resize_to_fill => [800, 600, :north]
  end

  version :thumbnail do
    resize_to_fit(150, 150)
  end


  def store_dir
    'banners/'
  end
end