module Image::Resizer
  extend ActiveSupport::Concern

  included do
    include Rails.application.routes.url_helpers
  end
  class_methods do
    def resize_attached_image(name, size: '500x500')
      define_method "#{name}_url" do
        return unless send(name).attached?

        rails_representation_url(send(name).variant(resize: size).processed)
      end
    end
  end
end
