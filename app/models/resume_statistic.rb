class ResumeStatistic < ApplicationRecord
  self.table_name = "resume_statistics"

  belongs_to :resume

  def record_view!
    increment!(:views)
    update!(last_viewed_at: Time.current)
  end

  def record_download!
    increment!(:downloads)
    update!(last_downloaded_at: Time.current)
  end
end
