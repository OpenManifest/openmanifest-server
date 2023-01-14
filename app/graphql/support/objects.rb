module Support::Objects
  extend ActiveSupport::Concern

  included do
    include Support::Objects::Fields
    include Support::Lookahead
  end
end
