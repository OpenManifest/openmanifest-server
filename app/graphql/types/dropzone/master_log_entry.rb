class Types::Dropzone::MasterLogEntry < Types::Base::Object
  field :id, ID, null: false
  field :date, GraphQL::Types::ISO8601Date, null: true
  field :dzso, Types::Dropzone::MasterLog::User, null: true
  field :notes, String, null: true
  field :location, Types::Dropzone::GeocodedLocation, null: true
  field :loads, [Types::Dropzone::MasterLog::Load], null: true
  field :download_url, String, null: true

  def date
    json.fetch(:date)
  end

  def notes
    json.fetch(:notes)
  end

  def dzso
    json.fetch(:dzso)
  end

  def location
    json.fetch(:location)
  end

  def loads
    json.fetch(:loads)
  end

  def json
    @json ||= object.generate_json
  end
end
