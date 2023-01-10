class MasterLog::Generate < ApplicationInteraction
  record :dropzone
  date_time :date, default: -> { DateTime.current }

  steps :generate

  def generate
    entry.save
    entry.store!
  end

  private

  def entry
    @entry ||= MasterLog.find_by(
      dropzone: dropzone,
      created_at: date.all_day
    ) || MasterLog.create!(
      dropzone: dropzone,
    )
  end
end
