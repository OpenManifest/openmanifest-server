class MasterLog < ApplicationRecord
  belongs_to :dzso, optional: true
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
      "loads.created_at > ?", created_at.beginning_of_day
    ).where(
      "loads.created_at < ?", created_at.end_of_day,
    ).order(created_at: :desc)
  end
end
