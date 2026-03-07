class ResumeStatistic < ApplicationRecord
  self.table_name = "resume_statistics"

  belongs_to :resume

  def record_view!
    self.class.where(id: id).update_all([ "views = views + 1, last_viewed_at = ?", Time.current ])
  end

  def record_download!
    self.class.where(id: id).update_all([ "downloads = downloads + 1, last_downloaded_at = ?", Time.current ])
  end
end
