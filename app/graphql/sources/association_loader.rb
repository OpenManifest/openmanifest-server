# frozen_string_literal: true

# Loads associations of many records at once (ActiveRecord's own preloader), so a field that reads an association of the
# record it belongs to costs one query for a whole list instead of one for each item (BUG-049):
#
#   dataloader.with(Sources::AssociationLoader, :slots).load(load)
#   load.slots # no query
#
# Several associations, or nested ones, can be given like to `includes`: `[:slots, { pilot: :user }]`. Associations that
# are already loaded are left alone.
class Sources::AssociationLoader < GraphQL::Dataloader::Source
  def initialize(associations)
    super()
    @associations = associations
  end

  def fetch(records)
    ::ActiveRecord::Associations::Preloader.new(records: records, associations: @associations).call
    records
  end
end
