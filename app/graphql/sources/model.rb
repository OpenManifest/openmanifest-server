class Sources::Model < GraphQL::Dataloader::Source
  attr_accessor :klass,
                :column,
                :cache_store

  def initialize(model, column: :id)
    self.klass = model
    self.column = column
  end

  def fetch(ids)
    unless (ids - record_cache.keys).empty?
      record_cache.merge!(
        get_records(ids).index_by(&column)
      )
    end
    record_cache.slice(*ids).values
  end

  private

  def record_cache
    cache_store[klass] ||= {}
  end

  def get_records(ids)
    @model_class.where(@column => ids)
  end

  def cache_store
    @cache_store ||= {}
  end
end
