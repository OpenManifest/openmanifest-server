module Support::Objects
  extend ActiveSupport::Concern

  included do
    include Support::Objects::Fields
  end
end
