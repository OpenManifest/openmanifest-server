class Sources::Model < GraphQL::Dataloader::Source
  attr_accessor :klass,
                :column
  attr_writer :cache_store

  def initialize(model, column: :id)
    self.klass = model
    self.column = column
  end

  # One result per key, in the order of the keys: nil and unknown keys give nil instead of shifting the other results
  def fetch(ids)
    unless (ids.compact - record_cache.keys).empty?
      record_cache.merge!(
        get_records(ids.compact).index_by(&column)
      )
    end
    ids.map { |id| record_cache[id] }
  end

  private

  def record_cache
    cache_store[klass] ||= {}
  end

  # Attached images come with the records: a list of members or dropzones shows one image each (BUG-049)
  def get_records(ids)
    attachments = klass.respond_to?(:reflect_on_all_attachments) ? klass.reflect_on_all_attachments : []
    attachments.reduce(klass.where(column => ids)) { |scope, attachment| scope.public_send(:"with_attached_#{attachment.name}") }
  end

  def cache_store
    @cache_store ||= {}
  end
end
