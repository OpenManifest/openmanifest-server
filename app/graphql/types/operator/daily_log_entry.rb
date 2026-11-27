class Types::Operator::DailyLogEntry < Types::Base::Object
  field :id, ID, null: false
  field :date, GraphQL::Types::ISO8601Date, null: true
  field :duty_officer, Types::Operator::DailyLog::User, null: true
  field :notes, String, null: true
  field :location, Types::Operator::GeocodedLocation, null: true
  field :loads, [Types::Operator::DailyLog::Load], null: true
  field :download_url, String, null: true
  field :template, String, null: true, description: "Which daily log the operator keeps: apf_log, flight_log or guest_list"
  field :csv, String, null: true, description: "The day's guest list as CSV: one row per person on each load"

  def template
    object.template
  end

  def csv
    object.to_csv(json)
  end

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
