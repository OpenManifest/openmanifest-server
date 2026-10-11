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

  def get_records(ids)
    klass.where(column => ids)
  end

  def cache_store
    @cache_store ||= {}
  end
end
