# == Schema Information
#
# Table name: master_logs
#
#  id          :integer          not null, primary key
#  dzso_id     :integer
#  dropzone_id :integer          not null
#  notes       :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class MasterLog < ApplicationRecord
  belongs_to :dzso, optional: true, class_name: "DropzoneUser"
  belongs_to :dropzone

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
  def loads
    # FIXME: This is gonna have timezone issues with servers in
    # different timezones
    Load.includes(:slots).where(
      plane_id: dropzone.planes.pluck(:id)
    ).where(
      "loads.created_at > ?", created_at
    ).where(
      "loads.created_at < ?", created_at + 24.hours,
    ).order(created_at: :desc)
  end
end
