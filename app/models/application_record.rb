class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  include ActiveStorageSupport::SupportForBase64
end
