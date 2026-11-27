# frozen_string_literal: true

require "csv"

# == Schema Information
#
# Table name: daily_logs
#
#  id          :bigint           not null, primary key
#  duty_officer_id     :bigint
#  operator_id :bigint           not null
#  notes       :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class DailyLog < ApplicationRecord
  belongs_to :duty_officer, optional: true,
                            class_name: "Membership"
  belongs_to :operator
  has_one_attached :json

  after_create :store!

  scope :at, -> (date) { find_or_create_by(date: date.to_date) }

  # 12.3.3 Master Log Contents
  # The DutyOfficer is responsible for ensuring that the master log contains:
  # (a) hours of CI attendance;
  # (b) the full name of the DutyOfficer;
  # (c) the full name of the GCA;
  # (d) location of the DZ;
  # (e) vehicle registration and pilot’s full name;
  # (f) Loadmaster’s full name;
  # (g) full name of each parachutist;
  # (h) exit height of each descent;
  # (i) type of descent, i.e. Tandem, AFF, SLD, IAD or experienced; and
  # (j) date of descent.
  def generate_json
    operator.to_daily_log(date).merge(
      duty_officer: duty_officer&.to_daily_log || {
        name: 'No DutyOfficer',
      },
      date: date.iso8601,
      notes: notes,
    )
  end

  # Which daily log the operator's template keeps (config/industries/*/template.yml `daily_log.template`): apf_log
  # (skydiving), flight_log (aviation) or guest_list (water and ground); nil for a template without one
  def template
    operator.industry_template.daily_log_template
  end

  CSV_COLUMNS = %w(load departure name phone email emergency_contact ticket escort).freeze

  # The guest list of the day as CSV: one row per person on each load (members, then the guests they escort), with how to
  # reach them and who to call for them. The headers are in the operator's words ("Trip", "Ticket", "With (adult)").
  #
  # @return [String]
  def to_csv(data = generate_json)
    CSV.generate do |csv|
      csv << CSV_COLUMNS.map { |column| operator.translate("daily_log_csv.#{column}") }
      data.fetch(:loads).each do |load|
        departure = load[:dispatch_at] || load[:departed_at]
        load_name = [load[:load_number], load[:name].presence].compact.join(" ")
        load.fetch(:slots).each do |slot|
          csv << [load_name, departure, *slot.values_at(:name, :phone, :email, :emergency_contact, :ticket_type, :escort)].map { |value| safe_cell(value) }
        end
      end
    end
  end

  def download_url
    Rails.application.routes.url_helpers.rails_blob_url(json)
  end

  def store!
    json.attach(
      io: StringIO.new(generate_json.to_json),
      filename: "daily-log-#{date.iso8601}.json",
      content_type: 'application/json'
    )
  end

  private

  # A cell that a spreadsheet would run as a formula is quoted as text (CSV injection); a phone number such as
  # "+61 400 000 000" stays as it is
  def safe_cell(value)
    text = value.to_s
    return text if text.match?(/\A\+[\d\s()-]+\z/)

    text.start_with?("=", "+", "-", "@", "\t", "\r") ? "'#{text}" : text
  end
end
