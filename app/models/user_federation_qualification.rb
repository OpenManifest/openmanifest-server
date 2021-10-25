class UserFederationQualification < ApplicationRecord
  belongs_to :user_federation
  belongs_to :qualification

  delegate :name, to: :qualification
end
