class Types::Operator::DailyLogEntry < Types::Base::Object
  field :id, ID, null: false
  field :date, GraphQL::Types::ISO8601Date, null: true
  field :duty_officer, Types::Operator::DailyLog::User, null: true
  field :notes, String, null: true
  field :location, Types::Operator::GeocodedLocation, null: true
  field :loads, [Types::Operator::DailyLog::Load], null: true
  field :download_url, String, null: true

  def date
    json.fetch(:date)
  end

  def notes
    json.fetch(:notes)
  end

  def duty_officer
    json.fetch(:duty_officer)
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
