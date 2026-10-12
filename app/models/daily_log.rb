# frozen_string_literal: true

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
end
