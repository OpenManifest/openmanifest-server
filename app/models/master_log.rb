# frozen_string_literal: true

# == Schema Information
#
# Table name: master_logs
#
#  id          :bigint           not null, primary key
#  dzso_id     :bigint
#  dropzone_id :bigint           not null
#  notes       :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class MasterLog < ApplicationRecord
  belongs_to :dzso, optional: true, class_name: "DropzoneUser"
  belongs_to :dropzone
  has_one_attached :json

  after_create :store!

  # 12.3.3 Master Log Contents
  # The DZSO is responsible for ensuring that the master log contains:
  # (a) hours of CI attendance;
  # (b) the full name of the DZSO;
  # (c) the full name of the GCA;
  # (d) location of the DZ;
  # (e) aircraft registration and pilot’s full name;
  # (f) Loadmaster’s full name;
  # (g) full name of each parachutist;
  # (h) exit height of each descent;
  # (i) type of descent, i.e. Tandem, AFF, SLD, IAD or experienced; and
  # (j) date of descent.
  def generate_json
    dropzone.to_master_log(created_at).merge(
      dzso: dzso&.to_master_log || 'No DZSO',
      date: created_at.to_date.iso8601,
    )
  end

  def store!
    json.attach(
      io: StringIO.new(generate_json.to_json),
      filename: "master-log-#{created_at.to_date.iso8601}.json",
      content_type: 'application/json'
    )
  end
end
